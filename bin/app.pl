#!/usr/bin/env perl

################################################################################
#                                                                              #
# fcollect - File Collector over HTTP(s)                                       #
#                                                                              #
# This web service will provide an API to dump files to a central location     #
# This is useful when reports are being generated on disparate servers, but    #
# the reports need to be viewed from a central location.                       #
#                                                                              #
# It is written in Perl using the Dancer2 Web Framework (a lightweight         #
# framework based on Sinatra for Ruby).  fcollect does not provide a web       #
# browser interface, but JSON can be sent and received as XMLHttpRequest       #
# object                                                                       #
#                                                                              #
#          see https://github.com/Q-Technologies/fcollect for full details     #
#                                                                              #
#                                                                              #
# Copyright 2015 - Q-Technologies (http://www.Q-Technologies.com.au            #
#                                                                              #
#                                                                              #
# Revision History                                                             #
#                                                                              #
#    Aug 2015 - Initial release                                                #
#                                                                              #
# Issues                                                                       #
#   *                                                                          #
#                                                                              #
################################################################################

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Plack::Builder;

use fcollect::api;

builder {
    mount '/api' => fcollect::api->to_app;
};


