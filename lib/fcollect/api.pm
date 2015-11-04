package fcollect::api;
################################################################################
#                                                                              #
# fcollect - Remotely manage the Xymon Configuration (API)                     #
#                                                                              #
# This web service will provide an API to manage the Xymon configuration       #
# from a remote system.  This makes it possible to automatically add/remove    #
# hosts to/from the hosts.cf file.  It currently support the following         #
# features:                                                                    #
#   * pages                                                                    #
#   * groups                                                                   #
#   * hosts (including multiple instances of same host)                        #
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
#    May 2015 - Initial release                                                #
#                                                                              #
# Issues                                                                       #
#   * only support group-compress and page (not vpage)                         #
#   * hosts.cfg files with lines spread over multiple lines are not supported  #
#                                                                              #
################################################################################

use Dancer2;
use Dancer2::Plugin::Ajax;
use fcollect;
use Data::Dumper;
use File::Basename;
use POSIX qw(strftime);
use 5.10.0;

use constant SUCCESS => "success";
use constant FAILED => "failed";

set serializer => 'JSON';
# Get Settings
$fcollect::debug_level = setting( 'debug_level' );
$fcollect::top_level_dir = setting( 'top_level_dir' );

our $VERSION = '0.1';

ajax '/login' => sub {
    my ( $result, $msg ) = check_login();
    { result => $result, message=> $msg };
};

ajax '/logout' => sub {
    session->destroy;
};

ajax '/upload' => sub {
    my $action = "upload";

    # Process inputs
    my %allparams = params;
    my $userid = param "userid";
    my $passwd = param "passwd";
    my $mode = param "mode";
    my $filename = param "filename";
    my $filepath = param "filepath";
    my $filecontents = param "filecontents";
    my $compresstype = param "compresstype";

    # Load and set up settings
    my $user = setting( 'user' );
    my $pass = setting( 'pass' );

    my $result = FAILED;
    my $msg = "";
    my $log = [];

    #debug (Dumper( request ) );

    # Check whether the user is logged in
    ( $result, $msg ) = check_login();
    return { result => $result, action => $action, message=> $msg } if( $result ne SUCCESS );

    # Send call save the file contents to disk
    my $ans = save_file_to_disk( { filename => $filename,
                                   filecontents => $filecontents,
                                   filepath => $filepath,
                                   mode => $mode,
                                   compresstype => $compresstype,
                                 } );

    #debug( "Answer: " . Dumper( $ans ) );
    $result = $ans->{result};
    $msg = $ans->{message}; 
    $log = $ans->{log}; 
    #my $request = request->body;
    my $request = JSON::to_json({ filename => $filename,
                                   filepath => $filepath,
                                   mode => $mode,
                                   compresstype => $compresstype,
                                 });
    $request =~ s/"/'/g;
    web_log( $user, $request, $result, $msg );

    debug join( "\n", @$log );

    { result => $result, action => $action, message=> $msg };


};

sub check_login {
    my $result = FAILED;
    my $msg;
    my $userid = param "userid";
    my $passwd = param "passwd";
    my $user = setting( 'user' );
    my $pass = setting( 'pass' );

    say join( " - ", $userid, $passwd ) if $fcollect::debug_level > 1;
    if( ( ! session('logged_in') or session('logged_in') ne 'true' )
        and     
        !($pass eq $passwd 
        and 
        $user eq $userid) 
      ){
        $msg = "ERROR: you must be logged in to do something!";
    } else {
        session logged_in => 'true';
        $result = SUCCESS;
        $msg = "Successfully logged and session started";
    }
    debug $msg if $fcollect::debug_level > 0;
    return ( $result, $msg );
}

sub web_log {
    my $web_log_format = setting( 'web_log_format' );
    my $web_log_path = setting( 'web_log_path' );
    my $h = request->env->{'REMOTE_HOST'};
    $h = "-" if ! $h;
    my $l = "-";
    my $u = request->env->{REMOTE_USER};
    $u = "-" if ! $u;
    my $t = strftime( "[%x:%X %z]", localtime );
    my $r = request->env->{REQUEST_URI};
    $r = "-" if ! $r;
    my $s = "200"; # Otherwise we wouldn't be here
    my $b = "-"; # Beyond the scope of what we want to do
    my $rfr = request->headers->{referer};
    $rfr = "-" if ! $rfr;
    my $ua = request->headers->{'user-agent'};
    $ua = "-" if ! $ua;
    my $usg = request->headers->{'x-requested-using'};
    $usg = "-" if ! $usg;
    my $src = request->headers->{'x-requested-source'};
    $src = "-" if ! $src;

    for( $web_log_format ){
        s/%h/$h/;
        s/%l/$l/;
        s/%u/$u/;
        s/%t/$t/;
        s/%r/$r/;
        s/%(>)*s/$s/;
        s/%b/$b/;
        s/%\{Referer\}i/$rfr/i;
        s/%\{User-agent\}i/$ua/i;
        s/%\{X-Requested-Using\}i/$usg/i;
        s/%\{X-Requested-Source\}i/$src/i;
    }

    #return;

    if( -w $web_log_path or ( -w dirname( $web_log_path ) and not -e $web_log_path )){
        if( open my $wl, ">>$web_log_path" ){
            print $wl $web_log_format . ' "'. join( '" "', @_ ) . "\"\n";
        } else {
            debug "Could not open the web log file ($web_log_path) for writing - unexpected error"
        }
    } else {
        debug "Could not open the web log file ($web_log_path) for writing - permission denied"
    }

}


true;
