#!/bin/sh

#set -o xtrace

platform="iphoneos"
ARCHS="i386 x86_64 armv7 armv7s arm64"
VERSION_DARWIN="15.6.0"
BUILD="x86_64-apple-darwin${VERSION_DARWIN}"

VERSION_OPENSSL_MAJOR="1.0"
VERSION_OPENSSL_MINOR="2i"
VERSION_OPENSSL="${VERSION_OPENSSL_MAJOR}.${VERSION_OPENSSL_MINOR}"
PARALLE=1

# Determine number of cores for (parallel) build
BUILD_THREADS=1
if [ "${PARALLEL}" != "false" ]; then
  BUILD_THREADS=$(sysctl hw.ncpu | awk '{print $2}')
fi

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
readonly ROOT_REL_OPENSSL="${path_build_root}/openssl-${VERSION_OPENSSL_MAJOR}/openssl-${VERSION_OPENSSL}/lib"
readonly ROOT_OPENSSL=$(cd "${path_build_root}/openssl-${VERSION_OPENSSL_MAJOR}/openssl-${VERSION_OPENSSL}/lib"; pwd)
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
  COMMONFLAGS="-arch ${ARCH} -isysroot ${SDK} -miphoneos-version-min=9.3"
  export CC="gcc"
  export CFLAGS="$COMMONFLAGS -I${SDK}/usr/include -I/Users/michael/Desktop/Reports/opt/lib/openssl-${VERSION_OPENSSL_MAJOR}/openssl-${VERSION_OPENSSL}/lib/include "
  export CXXFLAGS="$COMMONFLAGS "
  export LDFLAGS="$CFLAGS -DHAVE_OPENSSL -L${SDK}/usr/lib -L/Users/michael/Desktop/Reports/opt/lib/openssl-${VERSION_OPENSSL_MAJOR}/openssl-${VERSION_OPENSSL}/lib"
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
  #--with-openssl=/Users/michael/Desktop/Reports/opt/lib/openssl-${VERSION_OPENSSL_MAJOR}/openssl-${VERSION_OPENSSL}
  ./configure --prefix=${ROOT_INSTALL_FREETDS} --exec-prefix=${ROOT_INSTALL_FREETDS}/${ARCH} --host=${HOST} --build=${BUILD} --enable-msdblib --enable-static  --with-tdsver=${TDS_VER} --with-libiconv-prefix=${SDK}/lib CFLAGS="${CFLAGS}"

  SPACER="\n******************\n\n"

  printf SPACER

  make -j "${BUILD_THREADS}"

  printf SPACER

  make install

  printf SPACER

  LIBSYBDB+=("${ROOT_INSTALL_FREETDS}/${ARCH}/lib/libsybdb.a")
  LIBCT+=("${ROOT_INSTALL_FREETDS}/${ARCH}/lib/libct.a")

  printf "\n======== CHECK ARCH ========\n\n"
  xcrun -sdk iphoneos lipo -info ${ROOT_INSTALL_FREETDS}/${ARCH}/lib/libsybdb.a
  echo "\n======== CHECK DONE ========\n\n"


done

echo "== We just need static library == "
echo "== Copy headers to fat folder from i386 folder AND clean files in lib =="
cp -r ${CURRENTPATH}/build/${LIB}/i386/Include ${CURRENTPATH}/build/${LIB}/Include
#rm -rf ${CURRENTPATH}/build/${LIB}*

echo "Build library - libsybdb.a"

if [ ${#LIBSSL_IOS} -gt 0 ]; then
  echo "Build library for iOS..."
  lipo -create ${LIBSSL_IOS[@]} -output "${ROOT_INSTALL_FREETDS}/libsybdb.a"
  lipo -create ${LIBCRYPTO_IOS[@]} -output "${ROOT_INSTALL_FREETDS}/libct.a"
fi

mkdir -p ${ROOT_INSTALL_FREETDS}/Fat/lib
lipo -create ${ROOT_INSTALL_FREETDS}/i386/lib/libsybdb.a  ${ROOT_INSTALL_FREETDS}/armv7/lib/libsybdb.a  ${ROOT_INSTALL_FREETDS}/armv7s/lib/libsybdb.a  ${ROOT_INSTALL_FREETDS}/arm64/lib/libsybdb.a  ${ROOT_INSTALL_FREETDS}/x86_64/lib/libsybdb.a  -output ${ROOT_INSTALL_FREETDS}/libsybdb.a
lipo -create ${ROOT_INSTALL_FREETDS}/i386/lib/libct.a  ${ROOT_INSTALL_FREETDS}/armv7/lib/libct.a  ${ROOT_INSTALL_FREETDS}/armv7s/lib/libct.a  ${ROOT_INSTALL_FREETDS}/arm64/lib/libct.a  ${ROOT_INSTALL_FREETDS}/x86_64/lib/libct.a  -output ${ROOT_INSTALL_FREETDS}/libct.a

printf "\n======== CHECK FAT ARCH ========\n\n"

xcrun -sdk iphoneos lipo -info ${ROOT_INSTALL_FREETDS}/libsybdb.a

printf "\n======== CHECK DONE ========\n\n"

echo "== Done =="
