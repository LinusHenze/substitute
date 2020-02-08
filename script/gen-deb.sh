#!/bin/bash
set -e
debroot=out/debroot
version="$(git describe --always --dirty | sed 's/-/+/g')"
rm -rf $debroot
mkdir -p $debroot
mkdir -p $debroot/usr/share/doc/substitute
cp doc/installed-README.txt $debroot/usr/share/doc/README.txt
cp substrate/lgpl-3.0.tar.xz $debroot/usr/share/doc/
mkdir -p $debroot/usr/lib
cp out/libsubstitute.dylib $debroot/usr/lib/libsubstitute.0.dylib
ln -s libsubstitute.0.dylib $debroot/usr/lib/libsubstitute.dylib
mkdir -p $debroot/usr/include/substitute
cp lib/substitute.h $debroot/usr/include/substitute/
cp substrate/substrate.h $debroot/usr/include/substitute/
mkdir -p $debroot/Library
mkdir -p $debroot/System/Library/Substitute/DynamicLibraries
cp darwin-bootstrap/safemode-ui-hook.plist out/safemode-ui-hook.dylib $debroot/System/Library/Substitute/DynamicLibraries/
mkdir -p $debroot/System/Library/Substitute/Helpers
cp out/{posixspawn-hook.dylib,bundle-loader.dylib,unrestrict,inject-into-launchd,substituted} $debroot/System/Library/Substitute/Helpers/
mkdir -p $debroot/etc/rc.d
ln -s /System/Library/Substitute/Helpers/inject-into-launchd $debroot/etc/rc.d/substitute
mkdir -p $debroot/Library/LaunchDaemons
cp darwin-bootstrap/com.ex.substituted.plist $debroot/Library/LaunchDaemons/
mkdir -p $debroot/Applications/SafetyDance.app
ln -s /System/Library/Substitute $debroot/Library/Substitute
ln -s /System/Library/Substitute $debroot/Library/MobileSubstrate
cp -a out/SafetyDance.app/{*.png,Info.plist,SafetyDance} $debroot/Applications/SafetyDance.app/
cp -a darwin-bootstrap/DEBIAN $debroot/
sed "s#{VERSION}#$version#g" darwin-bootstrap/DEBIAN/control > $debroot/DEBIAN/control
#... add bootstrap stuff
# yay, old forks and deprecated compression
rm -f out/*.deb
fakeroot dpkg-deb -Zlzma -b $debroot out/com.ex.substitute-$version.deb
