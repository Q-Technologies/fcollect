#!/usr/bin/perl

use strict;
use JSON;
use YAML qw(LoadFile);
use MIME::Base64;
use File::Temp qw/ tempfile tempdir /;
use 5.10.0;

our $DEBUG = 0;
my $retries = 0; # How many times to attempt the upload
my $wait = int rand 10; # sleep for random time to spread load on web server
my ($config) = LoadFile('/etc/ap_linuxutil/submit2yum.yml');
my $username = $config->{user};
my $password = $config->{pass};
my $server_access = $config->{server_access};
my $server_data_url = "'$server_access/api/upload?userid=$username&passwd=$password'";

if( ! @ARGV ){
    say "Error: please provide at least one package to submit as the argument";
    exit 1;
}

my @pkgs = @ARGV;
for my $pkg ( @pkgs ){
    #say $pkg;
    if( ! -r $pkg ){
        say "Error: Skipping $pkg as it could not be read!";
        next;
    }
    my $contents;
    open IN, "<".$pkg or die $!;
    sysread IN, $contents, -s $pkg;
    close IN;

    my $data = { 
            'filename' => $pkg,
            'filepath' => "",
            'filecontents' => $contents,
            'compresstype' => "none",
            'mode' => "overwrite",
           } ;
 
    my $ans;
    send_data( $server_data_url, $data, \$ans ); 
    print $ans;
    
}

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


