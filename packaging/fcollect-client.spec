#
# spec file for package fcollect-client
#
Name:           fcollect-client
Version:        1.0.2
Release:        1.0.1
License:        Artistic
Summary:        fcollect client program
Url:            https://github.com/Q-Technologies/fcollect
Group:          Development/Libraries
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-build
Source: fcollect-client-1.0.2-1.0.1.tar.bz2

%description
The send2fcollect.pl script send a file of STDIN to the specified
fcollect service

%prep
rm -rf *

%setup -c 

%build

%pre
id  >/dev/null 2>&1
if [[ $? -eq 1 ]]; then
    useradd -r -d  
fi

%install
rm -rf $RPM_BUILD_ROOT/*
mkdir -p $RPM_BUILD_ROOT/usr/share/doc/fcollect-client/
mkdir -p $RPM_BUILD_ROOT//opt/local/bin
mkdir -p $RPM_BUILD_ROOT//etc/fcollect
mkdir -p $RPM_BUILD_ROOT//opt/local/bin/
mkdir -p $RPM_BUILD_ROOT//etc/fcollect/
mkdir -p $RPM_BUILD_ROOT/usr/share/doc/fcollect-client/
install -m 755 send2fcollect.pl $RPM_BUILD_ROOT//opt/local/bin/send2fcollect.pl
install -m 644 client.yml $RPM_BUILD_ROOT//etc/fcollect/client.yml
install -m 644 README.md $RPM_BUILD_ROOT/usr/share/doc/fcollect-client/README.md

%files
%defattr(644,root,root,755)
    /opt/local/bin
    /opt/local/bin/
%attr(755,root,root) /opt/local/bin/send2fcollect.pl
%attr(755,root,root) /etc/fcollect
%attr(600,root,root) /etc/fcollect/client.yml
%config /etc/fcollect/client.yml
%docdir /usr/share/doc/fcollect-client/
/usr/share/doc/fcollect-client/

%post
 
%clean
rm -rf $RPM_BUILD_ROOT
rm -rf %{_tmppath}/%{name}
rm -rf %{_topdir}/BUILD/%{name}

%preun

%changelog
* Thu Sep 10 2015 Q-Technologies
- initial version (1.0)
