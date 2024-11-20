#!/bin/sh

export PATH="./../../../usr/local/share:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

#set -o xtrace
#set -e

readonly prod_name="bzip2"
readonly prod_name_stylized="bzip2"
readonly prod_name_compiled_root="bz2"
readonly prod_name_compiled_prefix="lib"

readonly prod_default_version_major="1.0"
readonly prod_default_version_minor="6"
readonly prod_default_version="${prod_default_version_major}.${prod_default_version_minor}" # Default version in
readonly prod_version=$prod_default_version

readonly archs="x86_64 armv7 armv7s arm64 arm64e"

VERSION_DARWIN="18.5.0"
BUILD="x86_64-apple-darwin${VERSION_DARWIN}"
SDKVERSION="12.2"
TARGETSDKVERSION="10.0"

readonly prod_name_compiled="$prod_name_compiled_prefix$prod_name_compiled_root"
readonly prod_name_library="${prod_name_compiled}.a"

PARALLE=1

# Determine number of cores for (parallel) build
BUILD_THREADS=1
if [ "${PARALLEL}" != "false" ]; then
  BUILD_THREADS=$(sysctl hw.ncpu | awk '{print $2}')
fi

readonly true=0
readonly false=1

readonly prod_storage_protocol="http" #, https, or ftp
readonly prod_storage_prefix="www" #, https, or ftp
readonly archive_base_url="${prod_storage_protocol}://${prod_storage_prefix}.${prod_name}.org/${prod_version}/"
readonly archive_name="${prod_name_stylized}-${prod_version}"
readonly archive_name_extension="${archive_name}-${prod_version}.tar.gz"

readonly path_base=$( pwd )

readonly path_opt_prj="$(dirname "$path_base")"
readonly path_opt="$(dirname "$path_opt_prj")"

readonly path_media="${path_opt}/src"
readonly path_source="${path_opt}/src"
readonly path_library="${path_opt}/lib"
readonly path_build_root="${path_opt}/bld"

readonly path_media_archive="${path_media}/${archive_name_extension}"
readonly path_source_root="${path_source}/${archive_name}"

#Make lib directory for project
readonly ROOT_INSTALL_REL="${path_library}/${prod_name}"
mkdir -p $ROOT_INSTALL_REL
readonly ROOT_INSTALL_ABSOLUTE=$(cd "${ROOT_INSTALL_REL}"; pwd)

LIB=$prod_name

readonly DEVELOPER=`xcode-select -print-path`

CURRENTPATH=`pwd`
OLD_PATH=$PATH

cd "${path_source_root}"

for ARCH in ${archs}
do

  case "${ARCH}" in
    "i386"|"x86_64")
      PLATFORM="iPhoneSimulator"
      xcodebuild_platform="iphonesimulator"
      HOST="${ARCH}-apple-darwin${VERSION_DARWIN}"
      ;;
    "arm64")
      PLATFORM="iPhoneOS"
      xcodebuild_platform="iphoneos"
      HOST="aarch64-apple-darwin${VERSION_DARWIN}"
      ;;
    *)
      PLATFORM="iPhoneOS"
      xcodebuild_platform="iphoneos"
      HOST="${ARCH}-apple-darwin${VERSION_DARWIN}"
      ;;
  esac

  SDK=$( xcodebuild -version -sdk $xcodebuild_platform Path 2>/dev/null )
  export CC=$( xcrun -find gcc )
  export LD=$CC
  export HOST=${HOST}
  export BUILD=${BUILD}
  export ARCH=${ARCH}

  export PREFIX="${ROOT_INSTALL_ABSOLUTE}/${ARCH}"
  export BIGFILES=-D_FILE_OFFSET_BITS=64
  export LDFLAGS="-Os -arch ${ARCH} -Wl,-dead_strip -miphoneos-version-min=9.3 -L${ROOTDIR}/lib"
  export CFLAGS="-Os -arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDK} -miphoneos-version-min=9.3 -I${SDK}/include -g ${BIGFILES}"
  export CPPFLAGS="${CFLAGS}"
  export CXXFLAGS="${CFLAGS}"

  mkdir -p ${ROOT_INSTALL_ABSOLUTE}
  mkdir -p ${ROOT_INSTALL_ABSOLUTE}/${ARCH}
  rm -rf -- ${ROOT_INSTALL_ABSOLUTE}/${ARCH}

  make clean || printf "Nothing to make clean.\n"
  make -s distclean

  make -j "${BUILD_THREADS}" CC="${CC}" RANLIB="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" CFLAGS="${CFLAGS}"
  make install  PREFIX="${ROOT_INSTALL_ABSOLUTE}/${ARCH}" RANLIB="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib"

  xcrun -sdk iphoneos lipo -info ${ROOT_INSTALL_ABSOLUTE}/${ARCH}/lib/${prod_name_library}

  PROD_ARCHIVE_COMPILED+=("${ROOT_INSTALL_ABSOLUTE}/${ARCH}/lib/${prod_name_library}")

done

if [ ${#PROD_ARCHIVE_COMPILED} -gt 0 ]; then
  lipo -create ${PROD_ARCHIVE_COMPILED[@]} -output "${ROOT_INSTALL_ABSOLUTE}/${prod_name_library}"
fi

xcrun -sdk iphoneos lipo -info ${ROOT_INSTALL_ABSOLUTE}/${prod_name_library}
