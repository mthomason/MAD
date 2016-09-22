#!/bin/sh

set -o xtrace

platform="iphoneos"
ARCHS="i386 x86_64 armv7 armv7s arm64"
VERSION_DARWIN="15.6.0"
BUILD="x86_64-apple-darwin${VERSION_DARWIN}"

readonly name_freetds="freetds"
readonly name_freetds_stylized="freetds"
readonly version_freetds="1.00.15"

readonly archive_freetds_base_url="ftp://ftp.${name_freetds}.org/pub/${name_freetds_stylized}/stable/"
readonly archive_name="${name_freetds_stylized}-${version_freetds}"
readonly archive_name_extension="${archive_name}.tar.gz"

###
# Do not edit below here

readonly path_base=$( pwd )
readonly path_media="${path_base}/media"
readonly path_source="${path_base}/source"
readonly path_library="${path_base}/library"
readonly path_build_root="${path_base}/../opt/lib"

readonly path_media_archive="${path_media}/${archive_name_extension}"
readonly path_source_root="${path_source}/${archive_name}"

#OPENSSL PATHS
readonly ROOT_REL_OPENSSL="${path_build_root}/openssl-1.0/openssl-1.0.2h"
readonly ROOT_OPENSSL=$(cd "${path_build_root}/openssl-1.0/openssl-1.0.2h"; pwd)
readonly PTH_OPENSSL="${ROOT_OPENSSL}"
readonly LIB_OPENSSL="${ROOT_OPENSSL}"
readonly INC_OPENSSL="${ROOT_OPENSSL}/include"

#Make lib directory for project
ROOT_REL_FREETDS="${path_build_root}/${name_freetds}-${version_freetds}"
mkdir -p $ROOT_REL_FREETDS
readonly ROOT_INSTALL_FREETDS=$(cd "${ROOT_REL_FREETDS}"; pwd)

VERSION="1.00.15"
SDKVERSION="10.0"
TARGETSDKVERSION="9.3"
LIB="freetds"

DEVELOPER=`xcode-select -print-path`

CURRENTPATH=`pwd`
OLD_PATH=$PATH
TDS_VER=7.4

cd "${path_base}"
#download
#extract
cd "${path_source_root}"

for ARCH in ${ARCHS}
do
    case "${ARCH}" in
        "i386"|"x86_64")
            PLATFORM="iPhoneSimulator"
            HOST="${ARCH}-apple-darwin${VERSION_DARWIN}"
            ;;
        "arm64")
            PLATFORM="iPhoneOS"
            HOST="aarch64-apple-darwin${VERSION_DARWIN}"
            ;;
        *)
            PLATFORM="iPhoneOS"
            HOST="${ARCH}-apple-darwin${VERSION_DARWIN}"
            ;;
    esac

    SDK="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk"
export CC="gcc"
COMMONFLAGS="-arch ${ARCH} -isysroot ${SDK} -miphoneos-version-min=9.3"
    export CFLAGS="$COMMONFLAGS -I${SDK}/usr/include -I/Users/michael/Desktop/Reports/opt/lib/openssl-1.0/openssl-1.0.2h/include"
    export CXXFLAGS="$COMMONFLAGS -L{SDK}/usr/lib -L/Users/michael/Desktop/Reports/opt/lib/openssl-1.0/openssl-1.0.2h"
    export LDFLAGS="$CFLAGS"
    export LD=$CC
    # export CFLAGS="-arch ${ARCH} -miphoneos-version-min=${TARGETSDKVERSION} -isysroot ${SDK}"
    
    PREFIX="${CURRENTPATH}/build/${LIB}/${ARCH}"

    mkdir -p ${ROOT_INSTALL_FREETDS}
    mkdir -p ${ROOT_INSTALL_FREETDS}/${ARCH}

    echo "******************"
    echo "Please stand by..."
    echo "******************"

make clean
#--with-gnutls
#--with-openssl=/Users/michael/Desktop/Reports/opt/lib/openssl-1.0/openssl-1.0.2h
#--with-openssl=/Users/michael/Desktop/Reports/opt/lib/openssl-1.1/openssl-1.1.0
    ./configure  --with-openssl=/Users/michael/Desktop/Reports/opt/lib/openssl-1.0/openssl-1.0.2h  --prefix=${ROOT_INSTALL_FREETDS} --exec-prefix=${ROOT_INSTALL_FREETDS}/${ARCH} --host=${HOST} --build=${BUILD} --enable-msdblib --enable-static  --with-tdsver=${TDS_VER} --with-libiconv-prefix=${SDK}/lib CFLAGS="${CFLAGS}"

echo "******************"
    make
echo "******************"
    make install
echo "******************"

    echo "======== CHECK ARCH ========"
    xcrun -sdk iphoneos lipo -info ${ROOT_INSTALL_FREETDS}/lib/libsybdb.a
    echo "======== CHECK DONE ========"


done

echo "== We just need static library == "
echo "== Copy headers to fat folder from i386 folder AND clean files in lib =="
cp -r ${CURRENTPATH}/build/${LIB}/i386/ ${CURRENTPATH}/build/${LIB}/Fat
rm -rf ${CURRENTPATH}/build/${LIB}/Fat/lib/*

echo "Build library - libsybdb.a"
lipo -create ${CURRENTPATH}/build/${LIB}/i386/lib/libsybdb.a  ${CURRENTPATH}/build/${LIB}/armv7/lib/libsybdb.a  ${CURRENTPATH}/build/${LIB}/armv7s/lib/libsybdb.a  ${CURRENTPATH}/build/${LIB}/arm64/lib/libsybdb.a  ${CURRENTPATH}/build/${LIB}/x86_64/lib/libsybdb.a  -output ${CURRENTPATH}/build/${LIB}/Fat/lib/libsybdb.a

echo "======== CHECK FAT ARCH ========"
xcrun -sdk iphoneos lipo -info ${CURRENTPATH}/build/${LIB}/Fat/lib/libsybdb.a
echo "======== CHECK DONE ========"

echo "== Done =="
