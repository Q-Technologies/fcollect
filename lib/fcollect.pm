package fcollect;
################################################################################
#                                                                              #
# fcollect - File Collector over HTTP(s)                                       #
#                                                                              #
# This module provides the ability to dump files to a central location         #
# This is useful when reports are being generated on disparate servers, but    #
# the reports need to be viewed from a central location.                       #
#                                                                              #
#          see https://github.com/Q-Technologies/fcollect for project info     #
#                                                                              #
# Copyright 2015 - Q-Technologies (http://www.Q-Technologies.com.au)           #
#                                                                              #
#                                                                              #
# Revision History                                                             #
#                                                                              #
#    Aug 2015 - Initial release.                                               #
#                                                                              #
################################################################################

use strict;
use Data::Dumper;
use YAML qw(Dump Load);
use File::Path qw(make_path);
use File::Copy;
use File::Basename;
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);
#use IO::Uncompress::Inflate qw(inflate $InflateError);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
#use IO::Uncompress::UnLzma;
#use IO::Uncompress::UnLzf;
#use IO::Uncompress::UnXz;
#use IO::Uncompress::UnLzop;
use MIME::Base64;
use POSIX qw/strftime/;
use Socket;
use 5.10.0;

use Exporter qw(import);
our @ISA =   qw(Exporter);
our @EXPORT = qw(save_file_to_disk);

use constant SUCCESS => "success";
use constant FAILED => "failed";

# Define globals
our $VERSION = '0.1';
my @log;

# Define variables to hold settings
our $debug_level;
our $top_level_dir;

sub save_file_to_disk {
    # This sub will save file to the specified location on disk
    my ( $result, $msg );
    $msg = "Successfully saved the file to disk";
    my $newfile;
    my $fullpath;

    # capture arguments
    my $allparams = $_[0];
    my $mode = $allparams->{mode};
    my $filename = $allparams->{filename};
    my $filepath = $allparams->{filepath};
    my $compresstype = $allparams->{compresstype};
    my $filecontents = $allparams->{filecontents};

    # Check we can write to top level dirctory
    if( ! -w $top_level_dir ){
        $result = FAILED;
        $msg = "ERROR: coult not write to $top_level_dir";
    } else {
        $result = SUCCESS;
    }

    # Create the full path to the directory where file will reside
    if( $result eq SUCCESS ){
        # strip any upwards '..', etc
        ($filepath, $filename ) = File::Spec->no_upwards( ($filepath, $filename ));
        $fullpath = File::Spec->catdir( ( $top_level_dir, $filepath ) );
        eval { make_path($fullpath) };
        if ($@) {
            $result = FAILED;
            $msg = "ERROR: Couldn't create $fullpath: $@";
            debug( $msg, __LINE__ ) if $debug_level > 0;
        } else {
            if( ! -w $fullpath ){
                $result = FAILED;
                $msg = "ERROR: coult not write to $fullpath";
            } else {
                $result = SUCCESS;
            }
        }
    }

    # Check where file exists and whether we have been told to overwrite or append
    if( $result eq SUCCESS ){
        $newfile = File::Spec->catfile( ( $fullpath ), $filename );
        if( -e $newfile and $mode !~ /^(overwrite|append)$/ ){
            $result = FAILED;
            $msg = "ERROR: $newfile already exists and 'overwrite' or 'append' has not been turned on";
        } else {
            $result = SUCCESS;
        }
    }

    # Check whether the specified compression is supported and uncompress if so
    if( $result eq SUCCESS ){
        my ($buf1, $buf2);
        if( $compresstype eq "none" ){
            $result = SUCCESS;
        } elsif( $compresstype =~ /^(gzip|bzip2|lzma|lzf|xz|lzop|zlib)$/ ){
            eval { $buf1 = decode_base64($filecontents) }; 
            if ($@) {
                $result = FAILED;
                $msg = "ERROR: Couldn't decode the file contents: $@";
            } else {
                say $buf1;
                if( $compresstype eq "gzip" ){
                    eval { gunzip \$buf1 => \$buf2, Transparent => 0 or die "gunzip failed: $GunzipError\n"}; 
                } elsif( $compresstype eq "bzip2" ){
                    eval { bunzip2 \$buf1 => \$buf2, Transparent => 0 or die "bunzip2 failed: $Bunzip2Error\n"}; 
                #} elsif( $compresstype eq "lzma" ){
                    #eval { unlzma \$buf1 => \$buf2, Transparent => 0 }; 
                #} elsif( $compresstype eq "lzf" ){
                    #eval { unlzf \$buf1 => \$buf2, Transparent => 0 }; 
                #} elsif( $compresstype eq "xz" ){
                    #eval { unxz \$buf1 => \$buf2, Transparent => 0 }; 
                #} elsif( $compresstype eq "lzop" ){
                    #eval { unlzop \$buf1 => \$buf2, Transparent => 0 }; 
                #} elsif( $compresstype eq "zlib" ){
                    #eval { inflate \$buf1 => \$buf2, Transparent => 0 or die "inflate failed: $InflateError\n" }; 
                }
                if ($@ or not $buf2 ) {
                say $buf2;
                    $result = FAILED;
                    $msg = "ERROR: Couldn't uncompress the file contents: $@";
                } else {
                    $filecontents = $buf2;
                    $result = SUCCESS;
                }
            }
        } else {
            $result = FAILED;
            $msg = "ERROR: Unknown compression format";
        }
    }

    # Save the file to disk
    if( $result eq SUCCESS ){
        if( $mode eq "append" ){
            eval { open FILE, ">>$newfile" };
        } else {
            eval { open FILE, ">$newfile" };
        }
        if ($@) {
            $result = FAILED;
            $msg = "ERROR: Couldn't open $newfile for writing: $@";
            debug( $msg, __LINE__ ) if $debug_level > 0;
        } else {
            print FILE $filecontents;
            close FILE;
        }
    }

    return { result => $result, message=> $msg, log => \@log };
  
}



1;
