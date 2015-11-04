#
# spec file for package fcollect
#
Name:           fcollect
Version:        1.0.2
Release:        1.0.1
License:        Artistic
Summary:        File collector over http(s)
Url:            https://github.com/Q-Technologies/fcollect
Group:          Applications/System
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-build
Provides: localperl
Source: fcollect-1.0.2-1.0.1.tar.bz2

%description
This package provides a web service that enables the dropping of files into a specific directory.  See
https://github.com/Q-Technologies/fcollect for more details.

%prep
rm -rf *

%setup -c 

%build

%pre
id fcollect >/dev/null 2>&1
if [[ $? -eq 1 ]]; then
    useradd -r -d /opt/fcollect fcollect
fi

%install
rm -rf $RPM_BUILD_ROOT/*
mkdir -p $RPM_BUILD_ROOT/var/log/fcollect
mkdir -p $RPM_BUILD_ROOT/etc/init.d
mkdir -p $RPM_BUILD_ROOT/etc/sysconfig
mkdir -p $RPM_BUILD_ROOT/usr/share/doc/fcollect/
mkdir -p $RPM_BUILD_ROOT//opt/fcollect
mkdir -p $RPM_BUILD_ROOT//opt/fcollect/
mkdir -p $RPM_BUILD_ROOT//opt/fcollect/environments
mkdir -p $RPM_BUILD_ROOT//opt/fcollect/lib
mkdir -p $RPM_BUILD_ROOT//opt/fcollect/bin
mkdir -p $RPM_BUILD_ROOT//opt/fcollect/lib/fcollect
mkdir -p $RPM_BUILD_ROOT/usr/share/doc/fcollect/
install -m 644 config.yml $RPM_BUILD_ROOT//opt/fcollect/config.yml
install -m 755 bin/app.pl $RPM_BUILD_ROOT//opt/fcollect/bin/app.pl
install -m 644 environments/production.yml $RPM_BUILD_ROOT//opt/fcollect/environments/production.yml
install -m 644 lib/fcollect.pm $RPM_BUILD_ROOT//opt/fcollect/lib/fcollect.pm
install -m 644 lib/fcollect/api.pm $RPM_BUILD_ROOT//opt/fcollect/lib/fcollect/api.pm
install -m 644 LICENSE $RPM_BUILD_ROOT/usr/share/doc/fcollect/LICENSE
install -m 644 README.md $RPM_BUILD_ROOT/usr/share/doc/fcollect/README.md
install -m 644 $RPM_SOURCE_DIR/fcollect.rcfile $RPM_BUILD_ROOT/etc/init.d/fcollect
install -m 644 $RPM_SOURCE_DIR/fcollect.sysconfig $RPM_BUILD_ROOT/etc/sysconfig/fcollect

%files
%defattr(644,fcollect,fcollect,755)
    /opt/fcollect
    /opt/fcollect/
    /opt/fcollect/environments
    /opt/fcollect/lib
    /opt/fcollect/bin
    /opt/fcollect/lib/fcollect
%attr(755,fcollect,fcollect) /opt/fcollect/bin/app.pl
%attr(755,fcollect,fcollect) /var/log/fcollect
%attr(600,fcollect,fcollect) /opt/fcollect/config.yml
%config /opt/fcollect/config.yml
%attr(600,fcollect,fcollect) /opt/fcollect/environments/production.yml
%config /opt/fcollect/environments/production.yml
%attr(755,fcollect,fcollect) /etc/init.d/fcollect
%attr(644,fcollect,fcollect) /etc/sysconfig/fcollect
%config /etc/sysconfig/fcollect
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

%changelog
* Thu Sep 10 2015 Q-Technologies
- initial version (1.0)
