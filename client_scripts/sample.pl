#!/usr/bin/perl

use strict;
use JSON;
use MIME::Base64;
use 5.10.0;

my $wiki_page = "mst_config.txt";
my $wiki_topic = "puppet";
open SEND, "| /usr/local/bin/fcollect_send.pl -m overwrite -p $wiki_topic -f $wiki_page -c none" or die $!;

chomp( my $stamp = `date` );
chomp( my $hostname = `hostname -f` );

print SEND <<WIKI;
====== Puppet Master Config ======

Generated: **$stamp**, by ''$0'' on **$hostname**

^ Parameter ^ Value ^
WIKI

my @output = `puppet config print | sort`;
for( @output ){
    /^(.+)\s+=\s+(.*)$/;
    my( $key, $val ) = ( $1, $2 );
    $val =~ s|//|%%//%%|g;
    say SEND "| $key | $val |"
}
