%define	name	ntfsprogs
%define	ver	1.7.1
%define	rel	1
%define	prefix	/usr
%define bindir	/usr/bin
%define sbindir /usr/sbin
%define mandir	/usr/share/man


Summary		: NTFS filesystem libraries and utilities
Name		: %{name}
Version		: %{ver}
Release		: %{rel}
Source		: http://prdownloads.sf.net/linux-ntfs/ntfsprogs-%{ver}.tar.gz
Buildroot	: %{_tmppath}/%{name}-root
Packager	: Anton Altaparmakov <aia21@cantab.net>
License		: GPL
Group		: System Environment/Base
%description
The Linux-NTFS project (http://linux-ntfs.sf.net/) aims to bring full support
for the NTFS filesystem to the Linux operating system. Linux-NTFS currently
consists of a static library and utilities. This package contains the following
utilities:
	NtfsFix - Attempt to fix an NTFS partition that has been damaged by the
Linux NTFS driver. It should be run every time after you have used the Linux
NTFS driver to write to an NTFS partition to prevent massive data corruption
from happening when Windows mounts the partition.
IMPORTANT: Run this only *after* unmounting the partition in Linux but *before*
rebooting into Windows NT/2000! See man 8 ntfsfix for details.
	mkntfs - Format a partition with the NTFS filesystem. See man 8 mkntfs
for command line options.
	ntfslabel - Display/change the label of an NTFS partition. See man 8
ntfslabel for details.
	ntfsundelete - Recover deleted files from an NTFS volume.  See man 8
ntfsundelete for details.
	ntfsresize - Resize an NTFS volume. See man 8 ntfsresize for details.

%package devel
Summary		: files required to compile software that uses libntfs
Group		: Development/System
Requires	: ntfsprogs = %{ver}-%{rel}
%description devel
This package includes the header files and libraries needed to link software
with libntfs.


%prep
%setup

%build
if [ -n "$LINGUAS" ]; then unset LINGUAS; fi
%configure
make


%install
rm -rf "$RPM_BUILD_ROOT"
make DESTDIR="$RPM_BUILD_ROOT" install-strip


%clean
rm -rf "$RPM_BUILD_ROOT"


%files
%defattr(-,root,root)
%doc AUTHORS COPYING CREDITS ChangeLog INSTALL NEWS README TODO.include TODO.libntfs TODO.ntfsprogs doc/CodingStyle doc/attribute_definitions doc/attributes.txt doc/compression.txt doc/tunable_settings doc/template.c doc/template.h doc/system_files.txt doc/system_security_descriptors.txt
%{bindir}/*
%{sbindir}/*
%{mandir}/*/*
%{prefix}/lib/*.so*


%files devel
%defattr(-,root,root)
%{prefix}/include/*
%{prefix}/lib/*.a*
%{prefix}/lib/*.la*

%changelog
* Sat Jan 18 2003 Anton Altaparmakov <aia21@cantab.net>
- renamed to ntfsprogs.spec.in
- change source tar ball name to ntfsprogs

* Tue Dec 10 2002 Anton Altaparmakov <aia21@cantab.net>
- added ntfsresize

* Wed Jul 18 2002 Richard Russon <ntfs@flatcap.org>
- added ntfsundelete
- change TODO names

* Wed Jul 3 2002 Anton Altaparmakov <aia21@cantab.net>
- update my email address

* Mon Jun 3 2002 Anton Altaparmakov <aia21@cam.ac.uk>
- update %doc with new TODO files

* Tue Apr 12 2002 Anton Altaparmakov <aia21@cam.ac.uk>
- update %description text for ntfslabel

* Tue Mar 12 2002 Anton Altaparmakov <aia21@cam.ac.uk>
- update %description text

* Sat Jan 26 2002 Anton Altaparmakov <aia21@cam.ac.uk>
- update %description text
- make dependencies pick the right version automatically

* Thu Jan 10 2002 Anton Altaparmakov <aia21@cam.ac.uk>
- add dependency on linux-ntfs to linux-ntfs-devel
- update %description text

* Fri Nov 09 2001 Anton Altaparmakov <aia21@cam.ac.uk>
- update %description text
- (re)enable installation of shared libraries

* Wed Aug 22 2001 Anton Altaparmakov <aia21@cam.ac.uk>
- update %description text

* Thu Aug 2 2001 Anton Altaparmakov <aia21@cam.ac.uk>
- update %description text

* Wed Jul 25 2001 Anton Altaparmakov <aia21@cam.ac.uk>
- include sbin install path (mkntfs now is in sbin)

* Tue Jul 24 2001 Anton Altaparmakov <aia21@cam.ac.uk>
- update %description text

* Mon Jun 11 2001 Anton Altaparmakov <aia21@cam.ac.uk>
- remove duplicate %configure options
- remove shared library installation as shared libraries are disabled by
default

* Sun Jun 10 2001 Anton Altaparmakov <aia21@cam.ac.uk>
- add man pages stuff
- update info text
- add new doc/ stuff
- modify installation to do install-strip instead of install followed by manual
stripping
- update download URL to be the fast sourceforge http download server

* Fri Feb 2 2001 Anton Altaparmakov <aia21@cam.ac.uk>
- started changelog

