#!/usr/bin/perl
#
# This wrapper script allows for easily sending data from the shell

use strict;
use Data::Dumper;
use JSON;
use MIME::Base64;
use File::Temp qw/ tempfile tempdir /;
use Getopt::Std;
use IPC::Open2;
use 5.10.0;

our $DEBUG = 0;
my $retries = 0; # How many times to attempt the upload
my $wait = int rand 10; # sleep for random time to spread load on web server
my ($config) = LoadFile('config.yml');
my $username = $config->{user};
my $password = $config->{pass};
my $server_access = $config->{server_access};
my $server_data_url = "'$server_access/api/upload?userid=$username&passwd=$password'";

#
# Process command line options
our $opt_v; # Verbose
our $opt_h; # help
our $opt_f; # filename
our $opt_p; # file path
our $opt_m; # mode
our $opt_c; # compression

getopts('vhf:p:m:c:');

# The Help/Usage message
my $usage_msg = <<USAGE;

$0 [options] datafile

datafile is the path to a local file.  This contains the data that will be 
submitted.  STDIN will be read if there is no file specified.  

options:
\t\t-h this help message
\t\t-v display the result message
\t\t-m mode: overwrite, nooverwrite, append
\t\t-f filename: the remote filename
\t\t-p path: the remote path relative to the 'drop' root
\t\t-c compression type: what the data is compressed with.

Modes:
  overwrite - will write the new data regardless of whether there is an existing file or not
  nooverwrite - will throw an error if there is an existing file with the same name and path
  append - the new data will be appended to any existing with the same name and path, if no
           file currently exists, a new one will be created.

Compression:
  auto - the file's magic number will be used to guess the compression (if any)
  none - the data is not compressed
  bzip2 - the data has already been compressed in bzip2 format
  gzip - the data has already been compressed in gzip format

USAGE

if( $opt_h ){
    print $usage_msg;
    exit;
}

if( ! $opt_m or ! $opt_p or ! $opt_f ){
    say "The mode, path and filename must be specified";
    print $usage_msg;
    exit 1;
}

$opt_c = "auto" if ! $opt_c;
if( $opt_c !~ /^(bzip2|gzip|none|auto)$/ ){
    say "Unsupported compression type";
    print $usage_msg;
    exit 1;
}
if( scalar @ARGV > 1 ){
    say "too many files were specified - only one can be specified";
    print $usage_msg;
    exit 1;
}



# Main logic
my $contents;
if( scalar @ARGV == 1 ){
    open IN, "<".$ARGV[0] or die $!;
    my $filesize = -s $ARGV[0];
    sysread IN, $contents, $filesize;
    #while(<IN>){
        #$contents .= $_;
    #}
    close IN;
} else {
    while(<STDIN>){
        $contents .= $_;
    }
}

my $chunk = substr $contents, 0, 1024;
my $pid = open2(\*CHLD_OUT, \*CHLD_IN, '/usr/bin/file -') or die "open2 failed $!";
say CHLD_IN $chunk;
close CHLD_IN;
my $file = <CHLD_OUT>;

if( $file =~ /bzip2 compressed data/ ){
    $opt_c = "bzip2";
} elsif( $file =~ /gzip compressed data/ ){
    $opt_c = "gzip";
}

$contents = encode_base64( $contents ) if( $opt_c =~ /^(bzip2|gzip)$/ );

my $data = { 
            'filename' => $opt_f,
            'filepath' => $opt_p,
            'filecontents' => $contents,
            'compresstype' => $opt_c,
            'mode' => $opt_m,
           } ;
 
my $ans;
send_data( $server_data_url, $data, \$ans ); 
print $ans;

# Send data function
sub send_data{
    my $server_data_url = shift;
    my $data = shift;
    my $ans = shift;
    #$data = "data=".encode_base64( encode_json( $data ), "" );
    $data = encode_json( $data );

    my ($fh, $tmpfile) = tempfile();
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
    #print $output, "\n";
    $$ans = $output;
    if( $output =~ /success/ ){
        print "Successful\n" if $DEBUG;
        return 0;
    } else {
        print $output if $DEBUG;
        print "Unsuccessful\n" if $DEBUG;
        return 1;
    }
}


