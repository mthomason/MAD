#!/bin/sh

set -o xtrace
set -u

#cd mysql-connector-c-6.1.6-src-2

#get_cmake_property(_variableNames VARIABLES)
#foreach (_variableName ${_variableNames})
#    message(STATUS "${_variableName}=${${_variableName}}")
#endforeach()

#exit

# Get Latest iOS SDK name (i.e iphoneos6.1)

path_sdk_iphoneos=$(xcrun -sdk iphoneos --show-sdk-path)
#`xcodebuild -showsdks | tail -r | grep -m 1 iphoneos | awk -F"-sdk "  '{print $2}'`
path_sdk_iphonesimulator=$(xcrun -sdk iphonesimulator --show-sdk-path)
#`xcodebuild -showsdks | tail -r | grep -m 1 iphonesimulator | awk -F"-sdk "  '{print $2}'`

echo "Latest SDKs.."
echo $path_sdk_iphoneos
echo $path_sdk_iphonesimulator
echo


# Turn on debug 
set -x


# Build Release versions of mysqllib. Change to "-configuration Debug" to get debug one

cd mysql-connector-c-6.1.6-src
#cmake -G Xcode -DIPHONEOS_DEPLOYMENT_TARGET=7.0

#export SDKROOT=$( xcodebuild -version -sdk $sdk Path 2>/dev/null )
#export CC=$( xcrun -find gcc )
#export CFLAGS=" -arch armv7 -isysroot ${SDKROOT} -I${SDKROOT}/usr/include -miphoneos-version-min=${version_sdk_min} "
#export CPPFLAGS=" -arch armv7 -isysroot ${SDKROOT} -I${SDKROOT}/usr/include "

#mkdir -p armv7_target

#./configure --host=arm_apple_darwin7  --enable-static  --disable-shared --prefix="/Users/michael/Downloads/MySQLClient_iOS-master/mysql-connector-c-6.1.6-src/armv7"

#make && make install

xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk $path_sdk_iphonesimulator ONLY_ACTIVE_ARCH=NO ARCHS=i386 PRODUCT_NAME=mysqlclient_simulator

exit 55

#xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk $path_sdk_iphonesimulator ONLY_ACTIVE_ARCH=NO ARCHS=x86_64 PRODUCT_NAME=mysqlclient_device_armv7s
#xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk $path_sdk_iphoneos ONLY_ACTIVE_ARCH=NO ARCHS=armv7 PRODUCT_NAME=mysqlclient_device_armv7
#xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk $path_sdk_iphoneos ONLY_ACTIVE_ARCH=NO ARCHS=armv7s PRODUCT_NAME=mysqlclient_device_armv7s
#xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk $path_sdk_iphoneos ONLY_ACTIVE_ARCH=NO ARCHS=arm64 PRODUCT_NAME=mysqlclient_device_arm64

echo Done.
