# fcollect client
This is a client script for the fcollect service.  It makes it easy to send a file or piped text.

## Usage

    send2fcollect [options] datafile

where datafile is the path to a local file.  This contains the data that will be 
submitted.  STDIN will be read if there is no file specified.  

options:
 * -h display help message
 * -v display the result message
 * -m mode: 
   * overwrite - will write the new data regardless of whether there is an existing file or not
   * nooverwrite - will throw an error if there is an existing file with the same name and path
   * append - the new data will be appended to any existing with the same name and path, if no
           file currently exists, a new one will be created.
 * -f filename: the remote filename
 * -p path: the remote path relative to the 'drop' root
 * -c compression type: what the data is compressed with.
   * auto - the file's magic number will be used to guess the compression (if any)
   * none - the data is not compressed
   * bzip2 - the data has already been compressed in bzip2 format
   * gzip - the data has already been compressed in gzip format
 * -s service name - as specified in the configuration file ($config_file)

Configuration File (/etc/fcollect/config.yml)

    ---
      service1:
        user: "user1"
        pass: "secret1"
        server_access: "http://server.running.fcollect.on:port"
      service2:
        user: "user2"
        pass: "secret2"
        server_access: "http://server.running.fcollect.on:anotherport"

Multiple services can be specified in the one file.
