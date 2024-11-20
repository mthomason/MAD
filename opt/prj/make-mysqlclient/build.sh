#!/bin/sh



# Get Latest iOS SDK name (i.e iphoneos6.1)

IPHONEOS_SDK=`xcodebuild -showsdks | tail -r | grep -m 1 iphoneos | awk -F"-sdk "  '{print $2}'`
IPHONESIMULATOR_SDK=`xcodebuild -showsdks | tail -r | grep -m 1 iphonesimulator | awk -F"-sdk "  '{print $2}'`

echo "Latest SDKs.."
echo $IPHONEOS_SDK
echo $IPHONESIMULATOR_SDK
echo


# Turn on debug 
set -x


# Build Release versions of mysqllib. Change to "-configuration Debug" to get debug one

cd ../../src/mysql-connector-c-6.1.11-src
cmake -G Xcode -DIPHONEOS_DEPLOYMENT_TARGET=12.2 -WITH_SSL="/Users/michael/Desktop/Reports/opt/lib/openssl" #-DCMAKE_CROSSCOMPILING
#xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk $IPHONESIMULATOR_SDK ARCHS=i386 PRODUCT_NAME=mysqlclient_simulator
xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk $IPHONESIMULATOR_SDK ARCHS=x86_64 PRODUCT_NAME=mysqlclient_device_armv7s
xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk $IPHONEOS_SDK ARCHS=armv7 PRODUCT_NAME=mysqlclient_device_armv7
xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk $IPHONEOS_SDK ARCHS=armv7s PRODUCT_NAME=mysqlclient_device_armv7s
xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk $IPHONEOS_SDK ARCHS=arm64 PRODUCT_NAME=mysqlclient_device_arm64
xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk $IPHONEOS_SDK ARCHS=arm64e PRODUCT_NAME=mysqlclient_device_arm64e

echo Done.
