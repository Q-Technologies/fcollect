#!/usr/bin/perl

use strict;
use Data::Dumper;
use JSON;
use YAML qw(LoadFile);
use MIME::Base64;
use Test::More;
use Test::File;
use Test::Files;
use File::Copy;
use File::Spec;
use 5.10.0;

our $DEBUG = 0;
my $retries = 0; # How many times to attempt the upload
my $wait = int rand 10; # sleep for random time to spread load on web server


my ($config) = LoadFile('../config.yml');

my $username = $config->{user};
my $password = $config->{pass};

my $env = 'local';
#my $env = 'dev';
my $server_data_url;
if( $env eq 'dev' ){
    $server_data_url = "'https://remote-server/api/upload?userid=$username&passwd=$password'";
} elsif( $env eq 'local' ){
    my $cleanup = "find dropped -type f| grep -Ev '".'\.t\d+$'."' | xargs rm #2>/dev/null";
    `$cleanup`;
    $server_data_url = "'http://dev010:3002/api/upload?userid=$username&passwd=$password'";
} else {
    say "Unknown environment";
    exit 1;
}

my $modded;
my $refence;
my $data;
   
my @tests = ( 
              { name => 'create an initial file - do not specify compression - empty filepath',
                status => '{"action":"upload","message":"Successfully saved the file to disk","result":"success"}',
                nofilecreated => 0,
                data => { 
                          'filename' => "test1.txt",
                          'filepath' => "",
                          'filecontents' => "Some file contents",
                          'mode' => "overwrite",
                        } 
              }, 
              { name => 'create an initial file',
                status => '{"action":"upload","message":"Successfully saved the file to disk","result":"success"}',
                data => { 
                          'filename' => "test.txt",
                          'filepath' => "test/test/test",
                          'filecontents' => "Some file contents",
                          'mode' => "overwrite",
                          'compresstype' => "none",
                        } 
              }, 
              { name => 'repeat creation of file - do not overwrite',
                status => '{"action":"upload","message":"ERROR: testing/dropped/test/test/test/test.txt already exists and \'overwrite\' or \'append\' has not been turned on","result":"failed"}',
                ignorefile => 1,
                data => { 
                          'filename' => "test.txt",
                          'filepath' => "test/test/test",
                          'filecontents' => "Some file contents",
                          'mode' => "nooverwrite",
                          'compresstype' => "none",
                        } 
              }, 
              { name => 'repeat creation of file - do overwrite, don\'t specify compression',
                status => '{"action":"upload","message":"Successfully saved the file to disk","result":"success"}',
                data => { 
                          'filename' => "test.txt",
                          'filepath' => "test/test/test",
                          'filecontents' => "Some file contents",
                          'mode' => "overwrite",
                        } 
              }, 
            #);
#my @tests = ( 
              { name => 'set compression type to gzip but supply uncompressed data',
                status => '{"action":"upload","message":"ERROR: Couldn\'t uncompress the file contents: gunzip failed: Header Error: Bad Magic\n","result":"failed"}',
                nofilecreated => 1,
                data => { 
                          'filename' => "test_gzip.txt",
                          'filepath' => "test/test/test",
                          'filecontents' => "Some file contents",
                          'mode' => "overwrite",
                          'compresstype' => "gzip",
                        } 
              }, 
            #);
#my @tests2 = ( 
              { name => 'set compression type to gzip and supply compressed data',
                status => '{"action":"upload","message":"Successfully saved the file to disk","result":"success"}',
                data => { 
                          'filename' => "test_gzip.txt",
                          'filepath' => "test/test/test",
                          'filecontents' => "H4sIAGsO1VUAAwvJyCxWAKL0qsyCgtQUhZTEkkQuAAQl6YgVAAAA",
                          'mode' => "overwrite",
                          'compresstype' => "gzip",
                        } 
              }, 
              { name => 'set compression type to bzip2 but supply uncompressed data',
                status => '{"action":"upload","message":"ERROR: Couldn\'t uncompress the file contents: bunzip2 failed: Header Error: Bad Magic.\n","result":"failed"}',
                nofilecreated => 1,
                data => { 
                          'filename' => "test_bzip2.txt",
                          'filepath' => "test/test/test",
                          'filecontents' => "Some file contents",
                          'mode' => "overwrite",
                          'compresstype' => "bzip2",
                        } 
              }, 
              { name => 'set compression type to bzip2 and supply compressed data',
                status => '{"action":"upload","message":"Successfully saved the file to disk","result":"success"}',
                data => { 
                          'filename' => "test_bzip2.txt",
                          'filepath' => "test/test/test",
                          'filecontents' => "QlpoOTFBWSZTWRuo2KgAAALbgAAQQAAQAAQANGBMECAAIhM0TTZQgGgAaOaD7rYoKcr4u5IpwoSA3UbFQA==",
                          'mode' => "overwrite",
                          'compresstype' => "bzip2",
                        } 
              }, 
              { name => 'set compression type to bzip2 and supply compressed data - append to existing file',
                status => '{"action":"upload","message":"Successfully saved the file to disk","result":"success"}',
                data => { 
                          'filename' => "test_bzip2.txt",
                          'filepath' => "test/test/test",
                          'filecontents' => "QlpoOTFBWSZTWRuo2KgAAALbgAAQQAAQAAQANGBMECAAIhM0TTZQgGgAaOaD7rYoKcr4u5IpwoSA3UbFQA==",
                          'mode' => "append",
                          'compresstype' => "bzip2",
                        } 
              }, 
            );
for( my $i = 0; $i < @tests ; $i++ ){
    my $test = 't' . ($i + 1);
    my $data = $tests[$i]->{data};
    my $name = $tests[$i]->{name};
    my $status = $tests[$i]->{status};
    my $ans;
    $refence = File::Spec->catfile( ('t', $tests[$i]->{data}{filepath} ), $tests[$i]->{data}{filename} .".". $test );
    $modded = File::Spec->catfile( ('dropped', $tests[$i]->{data}{filepath} ), $tests[$i]->{data}{filename} );
    send_data( $server_data_url, $data, \$ans ); 
    is( $ans, $status, 'Check result for: ' .$name );
    if( $env eq 'local' and not $tests[$i]->{ignorefile} ){
        if( $tests[$i]->{nofilecreated} ){
            file_not_exists_ok( $modded, 'Check file does not exist for: ' .$name );
        } else {    
            compare_filter_ok($modded, $refence, \&ignore_blanks, 'Check file contents for: ' .$name );
        }
    }
}

done_testing();   # reached the end safely

sub ignore_blanks {
        my $line = shift;
        if( $line =~ /^\s*$/ ){
            return "";
        }
        return $line;
}

sub send_data{
    my $server_data_url = shift;
    my $data = shift;
    my $ans = shift;
    $data = encode_json( $data );

    my $tmpfile = "/tmp/post_data";
    open OUT, ">$tmpfile" or die $!;
    print OUT $data;
    close OUT;

    my $output = "";
    open CURL, "/opt/local/bin/curl -H 'X-Requested-With: XMLHttpRequest' -H 'X-Requested-Using: curl' -H 'X-Requested-Source: curl_test' -H 'Content-Type: application/json' -H 'Accept: application/json' --retry $retries --retry-delay $wait --connect-timeout 5 -s -k --noproxy \\* " . $server_data_url . " -d \@$tmpfile 2>&1 |";
    while(<CURL>){
        $output .= $_;
    }
    close CURL;
    unlink $tmpfile;
    $$ans = $output;
    if( $output =~ /success/ ){
        say "Successful" if $DEBUG;
        return 0;
    } else {
        print $output if $DEBUG;
        say "Unsuccessful" if $DEBUG;
        return 1;
    }
}


