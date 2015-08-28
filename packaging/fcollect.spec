#
# spec file for package fcollect
#
Name:           fcollect
Version:        1.0
Release:        1.0
License:        Artistic
Summary:        File collector over http(s)
Url:            https://github.com/Q-Technologies/fcollect
Group:          Applications/System
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-build
Requires:       perl(YAML)
 
%description
This package provides a web service that enables the dropping of files into a specific directory.  See
https://github.com/Q-Technologies/fcollect for more details.

%prep
rm -rf *

%build

%pre
id fcollect 2>/dev/null
if [[ $? -eq 1 ]]; then
    useradd -r -b /opt fcollect
fi

%install
rm -rf $RPM_BUILD_ROOT/*
mkdir -p $RPM_BUILD_ROOT/opt/fcollect
mkdir -p $RPM_BUILD_ROOT/opt/fcollect/bin
mkdir -p $RPM_BUILD_ROOT/opt/fcollect/lib
mkdir -p $RPM_BUILD_ROOT/opt/fcollect/lib/fcollect
mkdir -p $RPM_BUILD_ROOT/opt/fcollect/logs
mkdir -p $RPM_BUILD_ROOT/opt/fcollect/environments
mkdir -p $RPM_BUILD_ROOT/var/log/fcollect
mkdir -p $RPM_BUILD_ROOT/etc/init.d
mkdir -p $RPM_BUILD_ROOT/etc/cron.d
mkdir -p $RPM_BUILD_ROOT/etc/sysconfig
install -m 755 $RPM_SOURCE_DIR/bin/app.pl $RPM_BUILD_ROOT/opt/fcollect/bin/app.pl
install -m 644 $RPM_SOURCE_DIR/config.yml $RPM_BUILD_ROOT/opt/fcollect/config.yml
install -m 644 $RPM_SOURCE_DIR/environments/production.yml $RPM_BUILD_ROOT/opt/fcollect/environments/production.yml
install -m 644 $RPM_SOURCE_DIR/lib/fcollect.pm $RPM_BUILD_ROOT/opt/fcollect/lib/fcollect.pm
install -m 644 $RPM_SOURCE_DIR/lib/fcollect/api.pm $RPM_BUILD_ROOT/opt/fcollect/lib/fcollect/api.pm
mkdir -p $RPM_BUILD_ROOT/usr/share/doc/fcollect/
install -m 644 $RPM_SOURCE_DIR/README.md $RPM_BUILD_ROOT/usr/share/doc/fcollect/
install -m 644 $RPM_SOURCE_DIR/LICENSE $RPM_BUILD_ROOT/usr/share/doc/fcollect/
install -m 644 $RPM_SOURCE_DIR/fcollect_rcfile $RPM_BUILD_ROOT/etc/init.d/fcollect
install -m 644 $RPM_SOURCE_DIR/fcollect_sysconfig $RPM_BUILD_ROOT/etc/sysconfig/fcollect

%files
%defattr(644,fcollect,fcollect,755)
   /opt/fcollect/
   /var/log/fcollect
%attr(755,root,root) /etc/init.d/fcollect
%attr(644,root,root) /etc/sysconfig/fcollect
%config /etc/sysconfig/fcollect
%config /opt/fcollect/config.yml
%config /opt/fcollect/environments/production.yml
%docdir /usr/share/doc/fcollect/
/usr/share/doc/fcollect/

%post
chkconfig fcollect on
service fcollect start
 
%clean
rm -rf $RPM_BUILD_ROOT
rm -rf %{_tmppath}/%{name}
rm -rf %{_topdir}/BUILD/%{name}

%preun
chkconfig fcollect off
service fcollect stop

%postun
userdel fcollect

%changelog
* Mon May 25 2015 matt@Q-Technologies.com.au
- initial RPM version (1.0)

