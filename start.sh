set -a
appdir=/code/Dancer/fcollect
environment=development
workers=2
port=3002
plackup -s Starman -a $appdir/bin/app.pl -I $appdir/lib -E $environment -l :$port --workers=$workers
