#!/bin/sh

# you will need dh-make, dpkg-dev, fakeroot, cdbs

if [ $(basename $(pwd)) != 'nautilus-dropbox' ]; then
    echo "This script must be run from the nautilus-dropbox folder"
    exit -1
fi

BUILD=1
while [ $# != 0 ]; do
    flag="$1"
    case "$flag" in
        -n)
	    BUILD=0
            ;;
    esac
    shift
done


# creating a debian package is super bitchy and mostly hard to script

set -e

# get version
CURVER=$(awk '/^AC_INIT/{sub("AC_INIT\(\[nautilus-dropbox\],", ""); sub("\)", ""); print $0}' configure.in)

# clean old package build
rm -rf nautilus-dropbox{-,_}*

if [ ! -x configure ]; then
    ./autogen.sh
fi

if [ ! -e Makefile ]; then
    ./configure
fi

# first generate package binary
make dist

# untar package
tar xjf nautilus-dropbox-$CURVER.tar.bz2

# go into package dir
cd nautilus-dropbox-$CURVER

# make debian dir
mkdir debian

# add our files
cat > debian/rules <<EOF
#!/usr/bin/make -f

include /usr/share/cdbs/1/rules/debhelper.mk
include /usr/share/cdbs/1/class/autotools.mk

EOF
chmod a+x debian/rules

cat > debian/changelog <<EOF
nautilus-dropbox ($CURVER) stable; urgency=low

  * Initial Release, This package doesn't use a changelog

 -- Rian Hunter <rian@getdropbox.com>  $(date -R)
EOF

cat > debian/copyright <<EOF
This package was debianized by Rian Hunter <rian@getdropbox.com> on
$(date -R).

It was downloaded from https://www.getdropbox.com/download?dl=packages/nautilus-dropbox-$CURVER.tar.bz2

Upstream Author(s): 

    Rian Hunter <rian@getdropbox.com>

Copyright: 

    Copyright (C) 2009 Evenflow, Inc.

All images included in this package constitute data and are not licensed
for you to use under the terms of the GPL. You may not use the images
included in this package for any reason other than redistributing
this package without first obtaining permission from Evenflow, Inc.
You are explicitly forbidden from using these images in any other
software package. This includes the files:

/usr/share/icons/hicolor/16x16/apps/dropbox.png
/usr/share/icons/hicolor/22x22/apps/dropbox.png
/usr/share/icons/hicolor/24x24/apps/dropbox.png
/usr/share/icons/hicolor/32x32/apps/dropbox.png
/usr/share/icons/hicolor/48x48/apps/dropbox.png
/usr/share/icons/hicolor/64x64/apps/dropbox.png
/usr/share/icons/hicolor/64x64/emblems/emblem-dropbox-syncing.png
/usr/share/icons/hicolor/64x64/emblems/emblem-dropbox-uptodate.png
/usr/share/icons/hicolor/64x64/emblems/emblem-dropbox-unsyncable.png

All program source in this package is released under the terms of the
GNU GPL below.

    This package is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.
 
    This package is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
 
    You should have received a copy of the GNU General Public License
    along with this package; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

On Debian systems, the complete text of the GNU General
Public License can be found in \`/usr/share/common-licenses/GPL'.

The Debian packaging is (C) 2008, Rian Hunter <rian@getdropbox.com> and
is licensed under the GPL, see above.

# Please also look if there are files or directories which have a
# different copyright/license attached and list them here.
EOF


cat > debian/nautilus-dropbox.postinst<<'EOF'
#!/bin/sh
# postinst script for nautilus-dropbox
#
# see: dh_installdeb(1)

# summary of how this script can be called:
#        * <postinst> \`configure' <most-recently-configured-version>
#        * <old-postinst> abort-upgrade' <new version>
#        * <conflictor's-postinst> \`abort-remove' \`in-favour' <package>
#          <new-version>
#        * <postinst> \`abort-remove'
#        * <deconfigured's-postinst> \`abort-deconfigure' \`in-favour'
#          <failed-install-package> <version> \`removing'
#          <conflicting-package> <version>
# for details, see http://www.debian.org/doc/debian-policy/ or
# the debian-policy package

case "$1" in
    configure)
	gtk-update-icon-cache /usr/share/icons/hicolor > /dev/null 2>&1

        # stop dropbox
        dropbox stop > /dev/null 2>&1
        sleep 0.5
        killall dropbox > /dev/null 2>&1
        killall dropboxd > /dev/null 2>&1

        # kill all old installations 
        for I in /home/*/.dropbox-dist; do
          rm -rf "$I"
        done
        rm -rf ~/.dropbox-dist

        zenity --info --timeout=5 --text='Dropbox installation successfully completed! Please log out and log back in to complete the integration with your desktop. You can start Dropbox from your applications menu.' > /dev/null 2>&1
        if [ $? -ne 0 ]; then
          echo
          echo 'Dropbox installation successfully completed! Please log out and log back in to complete the integration with your desktop. You can start Dropbox from your applications menu.'
        fi

	;;

    abort-upgrade|abort-remove|abort-deconfigure)
    ;;

    *)
        echo "postinst called with unknown argument '\$1'" >&2
        exit 1
    ;;
esac

set -e

# dh_installdeb will replace this with shell code automatically
# generated by other debhelper scripts.

#DEBHELPER#

exit 0
EOF

cat > debian/control <<EOF
Source: nautilus-dropbox
Section: gnome
Priority: optional
Maintainer: Rian Hunter <rian@getdropbox.com>
Build-Depends: cdbs, debhelper (>= 5), build-essential, libnautilus-extension-dev (>= 2.16.0), libnotify-dev (>= 0.4.4), libglib2.0-dev (>= 2.14.0), python-gtk2 (>= 2.12), python-docutils
Standards-Version: 3.7.2

Package: nautilus-dropbox
Architecture: any
Depends: nautilus (>= 2.16.0), libnautilus-extension1 (>= 2.16.0), wget (>= 1.10.0), libnotify1 (>= 0.4.4), libglib2.0-0 (>= 2.14.0), python (>= 2.5), python-gtk2 (>= 2.12), \${shlibs:Depends}, \${misc:Depends}
Description: Dropbox integration for Nautilus
 Nautilus Dropbox is an extension that integrates
 the Dropbox web service with your GNOME Desktop.
 .
 Check us out at http://www.getdropbox.com/
EOF

if [ $BUILD -eq 1 ]; then
    dpkg-buildpackage -rfakeroot -k3565780E
else
    # Kind of silly but this is the easiest way to get this info the the build_slave.
    echo nautilus-dropbox-$CURVER > ../buildme
fi