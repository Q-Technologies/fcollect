#!/usr/bin/perl
#
# This wrapper script allows for easily sending data from the shell

use strict;
use Data::Dumper;
use JSON;
use YAML qw(LoadFile);
use MIME::Base64;
use File::Temp qw/ tempfile tempdir /;
use File::Basename;
use Getopt::Std;
use IPC::Open2;
use 5.10.0;

our $DEBUG = 0;
my $retries = 0; # How many times to attempt the upload
my $wait = int rand 10; # sleep for random time to spread load on web server
my $curl_bin = "/usr/bin/curl";
my $config_file = "/etc/fcollect/client.yml";
if( ! -e $config_file ){
    say "There was an unexpected error: $config_file does not exist!";
    exit 1;
}
if( ! -r $config_file ){
    say "You do not have sufficient permission to read $config_file!";
    exit 1;
}

#
# Process command line options
our $opt_v; # Verbose
our $opt_h; # help
our $opt_f; # filename
our $opt_p; # file path
our $opt_m; # mode
our $opt_s; # service
our $opt_c; # compression

getopts('vhf:p:m:c:s:');

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
\t\t-s service name - as specified in the configuration file ($config_file)

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

Configuration File ($config_file)
---
  service1:
    user: "user1"
    pass: "secret1"
    server_access: "http://server.running.fcollect.on:port"

USAGE

if( $opt_h ){
    print $usage_msg;
    exit;
}

#if( ! $opt_m or ! $opt_p or ! $opt_f or ! $opt_s ){
if( ! $opt_m or ! $opt_s ){
    #say "The mode, service, path and filename must be specified";
    usage_err( "The mode and service must be specified" );
}

$opt_c = "auto" if ! $opt_c;
if( $opt_c !~ /^(bzip2|gzip|none|auto)$/ ){
    usage_err( "Unsupported compression type" );
}
if( scalar @ARGV > 1 ){
    usage_err( "too many files were specified - only one can be specified" );
}
if( ! $opt_f ){
    if( scalar @ARGV == 1 ){
        $opt_f = basename( $ARGV[0] );
    } else {
        usage_err( "no file on the command line annd no filename was not specified" );
    }
}


# Read in the specified configuration
my ($config) = LoadFile($config_file);
my $username = $config->{$opt_s}{user};
my $password = $config->{$opt_s}{pass};
my $server_access = $config->{$opt_s}{server_access};
if( ! $username or ! $password or ! $server_access ){
    usage_err( "The specified service is not properly defined" );
}
my $server_data_url = "'$server_access/api/upload?userid=$username&passwd=$password'";



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
    open CURL, "$curl_bin -H 'X-Requested-With: XMLHttpRequest' -H 'X-Requested-Using: curl' -H 'X-Requested-Source: curl_test' -H 'Content-Type: application/json' -H 'Accept: application/json' --retry $retries --retry-delay $wait --connect-timeout 5 -s -k --noproxy \\* " . $server_data_url . " -d \@$tmpfile 2>&1 |";
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


sub usage_err{
    my $msg = shift;
    print $usage_msg;
    exit 1;
}

