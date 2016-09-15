#!/bin/sh

#  built_openssl.sh
#  openssl
#
#  Created by Michael on 9/14/16.
#


set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "ROOT DIR ${DIR}"


usage ()
{
	echo "usage: $0 [minimum iOS SDK version (default 8.2)]"
	exit 127
}

if [ $1 -e "-h" ]; then
	usage
fi

if [ -z $1 ]; then
	SDK_VERSION="8.2"
else
	SDK_VERSION=$1
fi

OPENSSL_VERSION="openssl-1.1.0"
DEVELOPER=`xcode-select -print-path`

echo "DEVELOPER Path: ${DEVELOPER}"

buildMac()
{

	ARCH=$1

    echo "BUILD Mac ${OPENSSL_VERSION} for ${ARCH}"

    FSHORTCUT=${DIR}/archive/${OPENSSL_VERSION}-MacOS-${ARCH}.short
    if [ -f $FSHORTCUT ]; then
        return
    fi

    echo "DIR `pwd`"

	TARGET="darwin-i386-cc"
	if [[ $ARCH == "x86_64" ]]; then
		TARGET="darwin64-x86_64-cc"
	fi
	pushd . > /dev/null

    mkdir -p ${DIR}/build/${OPENSSL_VERSION}
    mkdir -p ${DIR}/build/${OPENSSL_VERSION}/${ARCH}


    mkdir -p ${DIR}/archive
    mkdir -p ${DIR}/archive/${OPENSSL_VERSION}
    mkdir -p ${DIR}/archive/${OPENSSL_VERSION}/include/
    mkdir -p ${DIR}/archive/${OPENSSL_VERSION}/MacOS-${ARCH}
    mkdir -p ${DIR}/archive/${OPENSSL_VERSION}/MacOS-${ARCH}/include/
    mkdir -p ${DIR}/archive/${OPENSSL_VERSION}/MacOS-${ARCH}/include/openssl

    rm -rf ${DIR}/build/${OPENSSL_VERSION}/${ARCH}/*

    echo "CHANGE Directory ${OPENSSL_VERSION}/${ARCH}"
    cd "${DIR}/build/${OPENSSL_VERSION}/${ARCH}"

    export CROSS_TOP="\"${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer\""
    export CROSS_SDK="${PLATFORM}${SDK_VERSION}.sdk"
    export BUILD_TOOLS="${DEVELOPER}"
    export RANLIB="\"${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib\""

    echo "DIR `pwd`"

    echo "CONFIGURE"

    $DIR/source/$OPENSSL_VERSION/Configure ${TARGET} \
        --libdir="${DIR}/archive/${OPENSSL_VERSION}/MacOS-${ARCH}" \
        --openssldir="/tmp/${OPENSSL_VERSION}-${ARCH}" #&> "/tmp/${OPENSSL_VERSION}-${ARCH}.log"

    echo "MAKE"
    make --max-load=2 >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1



    echo "MAKE Test"
    cp *.dylib ${DIR}/archive/${OPENSSL_VERSION}/MacOS-${ARCH}/.
    cp *.a ${DIR}/archive/${OPENSSL_VERSION}/MacOS-${ARCH}/.
    cp include/openssl/opensslconf.h ${DIR}/archive/${OPENSSL_VERSION}/MacOS-${ARCH}/include/openssl/.
    cp include/openssl/opensslconf.h ${DIR}/archive/${OPENSSL_VERSION}/MacOS/.

    touch –a $FSHORTCUT
    #make test --max-load=2 >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1

    #echo "MAKE Install"
    #make install >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1

    #echo "MAKE Clean"
    #make clean >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1

	popd > /dev/null
}

buildIOS()
{
	ARCH=$1

    FSHORTCUT=${DIR}/archive/${OPENSSL_VERSION}-iPhoneOS-${ARCH}.short
    if [ -f $FSHORTCUT ]; then
        return
    fi

    echo "BUILD iOS ${ARCH}"
	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"

    echo "DIR `pwd`"

	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
		PLATFORMINT="iPhoneSimulator"
        local sdk="iphonesimulator${version_sdk}"
	else
		PLATFORMINT="iPhoneOS"
        local sdk="iphoneos${version_sdk}"
    #sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
	fi

    mkdir -p ${DIR}/build/${OPENSSL_VERSION}
    mkdir -p ${DIR}/build/${OPENSSL_VERSION}/${ARCH}

    mkdir -p ${DIR}/archive
    mkdir -p ${DIR}/archive/${OPENSSL_VERSION}
    mkdir -p ${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-${ARCH}

    rm -rf ${DIR}/build/${OPENSSL_VERSION}/${ARCH}/*

    echo "CHANGE Directory ${OPENSSL_VERSION}/${ARCH}"
    cd "${DIR}/build/${OPENSSL_VERSION}/${ARCH}"

    echo "DIR `pwd`"

path_xcode=$( xcode-select -print-path )

echo "XCODE select"

env_cross_top="${path_xcode}/Platforms/${PLATFORMINT}.platform/Developer"
env_cross_sdk="${PLATFORMINT}${version_ios}.sdk"
env_build_tools="${path_xcode}"
env_cc="\"$( xcode-select -print-path )/usr/bin/gcc\" -arch ${ARCH} "
env_isyroot=" -isysroot /Volumes/Thor/Applications/Xcode-8.app/Contents/Developer/Platforms/${PLATFORMINT}.platform/Developer/SDKs/${PLATFORMINT}.sdk "
echo "1"
export CROSS_TOP="${env_cross_top}"
echo "1"
export CROSS_SDK="${env_cross_sdk}"
echo "121"
export BUILD_TOOLS="${env_build_tools}"
echo "11"
export CC="${env_cc}"
echo "2"

developer_root=$( xcode-select -print-path )
echo "3"
platform_root=$( xcodebuild -version -sdk $sdk PlatformPath 2>/dev/null )
echo "4"

export DEVROOT="${platform_root}/Developer"
echo "5"
export SDKROOT=$( xcodebuild -version -sdk $sdk Path 2>/dev/null )
echo "6"
#export CFLAGS=" -arch ${ARCH} -isysroot ${SDKROOT} -I${SDKROOT}/usr/include -miphoneos-version-min=${version_sdk_min} "
echo "7"
#export CPPFLAGS=" -arch ${ARCH} -isysroot ${SDKROOT} -I${SDKROOT}/usr/include ${CPPFLAGS} "
echo "8"
export LD=$( xcrun -find ld )
echo "9"
export LDFLAGS="-arch ${ARCH} -L${SDKROOT}/usr/lib -miphoneos-version-min=${version_sdk_min} "

#export PLATFORM="${PLATFORMINT}"
#export CROSS_TOP="\"${DEVELOPER}/Platforms/${PLATFORMINT}.platform/Developer\""
#export CROSS_SDK="${PLATFORMINT}.sdk"
#export BUILD_TOOLS="\"${DEVELOPER}\""
#export LFLAG="${LFLAG} -arch ${ARCH}"
    export RANLIB="\"${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib\""
#export CC="/Volumes/Thor/Applications/Xcode-8.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc -arch ${ARCH}"
#export CFLAG=""
#export CFLAG="${CFLAG} -isysroot \"${DEVELOPER}/Platforms/${PLATFORMINT}.platform/Developer/SDKs/${PLATFORMINT}.sdk\" -miphoneos-version-min=${SDK_VERSION}"

	echo "Building ${OPENSSL_VERSION} for ${PLATFORMINT} ${SDK_VERSION} ${ARCH}"
	if [[ "${ARCH}" == "x86_64" ]]; then
        $DIR/source/$OPENSSL_VERSION/Configure darwin64-x86_64-cc \
            --libdir="${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-${ARCH}" \
            --openssldir="/tmp/${OPENSSL_VERSION}-iOS-${ARCH}" #&> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log"
	else
        $DIR/source/$OPENSSL_VERSION/Configure iphoneos-cross \
            --libdir="${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-${ARCH}" \
            --openssldir="/tmp/${OPENSSL_VERSION}-iOS-${ARCH}" #&> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log"
	fi

	# add -isysroot to CC=
#sed -ie "s!^CFLAG=!CFLAG=-isysroot \"${CROSS_TOP}/SDKs/${CROSS_SDK}\" -miphoneos-version-min=${SDK_VERSION} !" "Makefile"
    echo "MAKE"
    make #>> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log" 2>&1

    cp *.dylib ${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-${ARCH}/.
    cp *.a ${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-${ARCH}/.

    mkdir -p ${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-${ARCH}/include/
    mkdir -p ${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-${ARCH}/include/openssl
    cp include/openssl/opensslconf.h ${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-${ARCH}/include/openssl/.
    cp *.a ${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-${ARCH}/.
    touch –a $FSHORTCUT

#echo "MAKE Clean"
#make install
#make test --max-load=2 #>> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log" 2>&1
#echo "MAKE Clean"
#make clean --max-load=2 #>> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log" 2>&1
	popd > /dev/null
}
mkdir -p ${DIR}/archive/${OPENSSL_VERSION}/MacOS/.
mkdir -p ${DIR}/archive/${OPENSSL_VERSION}/include/
mkdir -p ${DIR}/lib/iOS
mkdir -p ${DIR}/Mac
mkdir -p ${DIR}/include/openssl/
mkdir -p ${DIR}/source
mkdir -p ${DIR}/build
mkdir -p ${DIR}/media

echo "REMOVE include/openssl/* lib/*"
rm -rf include/openssl/* lib/*
rm -rf "/tmp/${OPENSSL_VERSION}-*"
rm -rf "/tmp/${OPENSSL_VERSION}-*.log"
rm -rf "${OPENSSL_VERSION}"

cd ${DIR}/media

if [ ! -e ${OPENSSL_VERSION}.tar.gz ]; then
	echo "DOWNLOADING ${OPENSSL_VERSION}.tar.gz"
	curl -O https://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz
else
    echo "SKIPPING Download"
	echo "USING ${OPENSSL_VERSION}.tar.gz"
fi

echo "CHANGING Source Directory"
cd ${DIR}/source

echo "DIR `pwd`"

CDIR=`pwd`;

echo "DDD"
echo "${CDIR}/config"

rm -rf ${DIR}/source/*
#if [ ! -f ${CDIR}/config ]; then
    echo "UPACKING Openssl from Media"
    tar xfz "../media/${OPENSSL_VERSION}.tar.gz"
#else
#    echo "SKIPPING Unpacking"
#xfi

echo "CHANGING Build Directory"
cd ${DIR}/build

echo "DIR `pwd`"

buildMac "i386"
buildMac "x86_64"

echo "COPYING Headers"
cp -Rf ${DIR}/source/$OPENSSL_VERSION/include/* ${DIR}/archive/${OPENSSL_VERSION}/include/.

echo "BUILDING Mac libraries"

cd ${DIR}/archive

mkdir -p ${DIR}/archive/${OPENSSL_VERSION}/MacOS

lipo \
	"${DIR}/archive/${OPENSSL_VERSION}/MacOS-i386/libcrypto.a" \
	"${DIR}/archive/${OPENSSL_VERSION}/MacOS-x86_64/libcrypto.a" \
	-create -output ${DIR}/archive/${OPENSSL_VERSION}/MacOS/libcrypto.a

lipo \
	"${DIR}/archive/${OPENSSL_VERSION}/MacOS-i386/libssl.a" \
	"${DIR}/archive/${OPENSSL_VERSION}/MacOS-x86_64/libssl.a" \
	-create -output ${DIR}/archive/${OPENSSL_VERSION}/MacOS/libssl.a

echo "BUILDING iOS libraries"

echo "BUILDING iOS armv7"
buildIOS "armv7"

echo "BUILDING iOS arm64"
buildIOS "arm64"

echo "BUILDING iOS x86_64"
buildIOS "x86_64"


lipo \
	"${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-armv7/libcrypto.a" \
	"${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-arm64/libcrypto.a" \
	"${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-x86_64/libcrypto.a" \
	-create -output ${DIR}/archive/${OPENSSL_VERSION}/libcrypto.a

lipo \
	"${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-armv7/libssl.a" \
	"${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-arm64/libssl.a" \
	"${DIR}/archive/${OPENSSL_VERSION}/iPhoneOS-x86_64/libssl.a" \
	-create -output ${DIR}/archive/${OPENSSL_VERSION}/libssl.a

echo "CLEANING Up"
rm -rf /tmp/${OPENSSL_VERSION}-*
#rm -rf ${OPENSSL_VERSION}

echo "DONE"
                                       
