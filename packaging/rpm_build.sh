#!/bin/bash

dir=$(dirname $0)
remote_dir=rpmbuild
mkdir -p RPMS

for host in $@
do echo Building RPM on $host
	echo
	echo
	ssh $host mkdir -p ${remote_dir:?}/SOURCES ${remote_dir:?}/SPECS
	rsync -av --delete --exclude=\*.rpm ${dir:?}/bin \
        ${dir:?}/lib \
        ${dir:?}/environments/production.yml \
        ${dir:?}/config.yml \
        ${dir:?}/fcollect_rcfile \
        ${dir:?}/fcollect_sysconfig \
        ${dir:?}/README.md \
        ${dir:?}/LICENSE \
        $host:${remote_dir:?}/SOURCES
	rsync -av --delete --exclude=\*.rpm ${dir:?}/fcollect.spec $host:${remote_dir:?}/SPECS
	ssh $host rpmbuild -ba ${remote_dir:?}/SPECS/fcollect.spec
    rsync -av $host:${remote_dir:?}/SRPMS/ RPMS/
    rsync -av $host:${remote_dir:?}/RPMS/ RPMS/
done
