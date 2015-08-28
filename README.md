# fcollect - File Collector over HTTP(s)

This web service will provide an API to dump files to a central location.  This is useful when reports are being generated on disparate servers, but the reports need to be viewed from a central location.                                                                    

It is written in Perl using the Dancer2 Web Framework (a lightweight framework based on Sinatra for Ruby).  fcollect does not provide a web browser interface, but JSON can be sent and received as XMLHttpRequest object.

see https://github.com/Q-Technologies/fcollect for full details.

It is designed to be very simple leaving a lot of the control in the hands of the submitter.  The security measures in place include a:
  * signle username and password - only intended to stop random people submitting content
  * a configurable directory root for dropping content into - i.e. a client cannot just dump files anyware on the system
  * optionally, the service can easily be proxied behind an SSL frontent
The following features allow flexibility, but provide little protection over previously submitted content:
  * any authenticated user can overwrite any file within the configured root
  * any authenticated user can put a file anywhere within the configured root
  * the content of the files do not matter - they can be formatted text (e.g. wiki markup), plain text or binary files.  A separate process needs to index the files based on their contents.  This could be a wiki indexes or Apache automatic directory indexing.

## Installation

Install the RPM (nodeps is required as RPM will automatically make any perl modules reference into dependencies, which is a problem if you have installed those modules through CPAN):

    rpm -ivh --nodeps fcollect-1.0-1.0.noarch.rpm

### Prepare Environment

Install the following PERL modules:
  * Dancer2

Update the `/etc/sysconfig/fcollect` file with the correct location for the additional PERL modules.

### Set the location of the dropped file root
In `./environments/production.yml`, set the `top_level_dir`, e.g.:

    top_level_dir: "/data/pages/repmon/dropped"

Make sure the user fcollect is running as (fcollect) has permissions to write to this directory:

    mkdir /data/pages/repmon/dropped
    chown fcollect /data/pages/repmon/dropped


## Maintenance
### Changing the password
Change the password in the `config.yml` file and restart the web service.  Also change the password in any client scripts submitting data.
