#!/bin/sh

#  buildcounter.sh
#  MAD
#
#  Created by Michael Thomason on 3/4/14.
#  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.

# Tag major versions like "v3.0"

echo "Updating version/build number from git..."
plist=${PROJECT_DIR}/${INFOPLIST_FILE}
plistwatchkitext=${PROJECT_DIR}/MAD\ Designer\ WatchKit\ Extension/Info.plist
plistwatchkitapp=${PROJECT_DIR}/MAD\ Designer\ WatchKit\ App/Info.plist

versionnum=$( git describe --abbrev=1 --tags | awk '{split($0,a,"-"); print a[1]}' )
versionnum=${versionnum#"v"}

versionminor=$( git describe --abbrev=1 --tags | awk '{split($0,a,"-"); a[2]}' )
if [-n "$versionminor"]; then
    currentvnum=$( git describe --abbrev=1 --tags | awk '{split($0,a,"-"); print a[1] "." a[2]}' )
else
    currentvnum=$( git describe --abbrev=1 --tags | awk '{split($0,a,"-"); print a[1] ".0"}' )
fi

#Use this while developing.
currentvnum=$( git describe --abbrev=1 --tags | awk '{split($0,a,"-"); print a[1] "." a[2]}' )
currentvnum=${currentvnum#"v"}

buildnum=$( git rev-list HEAD --count )

if [[ "${versionnum}" == "" ]]; then
echo "No version number from git"
exit 2
fi

if [[ "${buildnum}" == "" ]]; then
echo "No build number from git"
exit 2
fi

/usr/libexec/Plistbuddy -c "Set CFBundleShortVersionString $currentvnum" "${plistwatchkitext}"
/usr/libexec/Plistbuddy -c "Set CFBundleShortVersionString $currentvnum" "${plistwatchkitapp}"
/usr/libexec/Plistbuddy -c "Set CFBundleShortVersionString $currentvnum" "${plist}"
echo "Updated version number to $versionnum"

/usr/libexec/Plistbuddy -c "Set CFBundleVersion $currentvnum" "${plistwatchkitext}"
/usr/libexec/Plistbuddy -c "Set CFBundleVersion $currentvnum" "${plistwatchkitapp}"
/usr/libexec/Plistbuddy -c "Set CFBundleVersion $currentvnum" "${plist}"
echo "Updated build number to $currentvnum"

/usr/libexec/Plistbuddy -c "Set MADRev $buildnum" "${plist}"
echo "Updated build number to $buildnum"

filelocation=${PROJECT_DIR}/MADStack/MADDesigner/MADAppConfiguration.m
sed -ie "s/NSString \* const MTGlobalBundleVersion.*/NSString \* const MTGlobalBundleVersion                              = @\"${currentvnum}\";/g" "${filelocation}"
sed -ie "s/NSString \* const MTGlobalBundleShortVersion.*/NSString \* const MTGlobalBundleShortVersion                         = @\"${currentvnum}\";/g" "${filelocation}"
sed -ie "s/NSString \* const MTGlobalBundleRev.*/NSString \* const MTGlobalBundleRev                                  = @\"${buildnum}\";/g" "${filelocation}"
