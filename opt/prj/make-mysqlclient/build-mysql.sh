#!/bin/sh
set -o xtrace
export PATH="./../../../usr/local/share:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

readonly path_base=$( pwd )

readonly path_opt="$(dirname "$path_base")"
readonly path_opt_prj="$(path_base)"

readonly prod_name="mysqlconnector"
readonly prod_name_stylized="mysqlconnector"
readonly prod_name_compiled_root="mysqlconnector"
readonly prod_name_compiled_prefix="lib"

readonly path_media="${path_opt}/src"
readonly path_source="${path_opt}/src"
readonly path_library="${path_opt}/lib"
readonly path_build_root="${path_opt}/bld"

build_type="Release"

archs="arm64 arm64e armv7 armv7s"

DEVELOPER=`xcode-select -print-path`

path_project_directory="${path_build_root}/${prod_name}"
path_project="${path_project_directory}/LibMySQL.xcodeproj"

path_platform_for_sdk() {
  local path=$( xcodebuild -version -sdk "${1}" PlatformPath 2>/dev/null )
  printf "%s" "${path}"
}

path_sdk_for_sdk() {
  local path=$( xcodebuild -version -sdk "${1}" Path 2>/dev/null )
  printf "%s" "${path}"
}

platform_for_arch() {
    local version=$( xcodebuild -version -sdk "${1}" SDKVersion 2>/dev/null )
    printf "%s" "${version}"
}

version_for_platform() {
    local version=$( xcodebuild -version -sdk "${1}" SDKVersion 2>/dev/null )
    printf "%s" "${version}"
}
path_media_mysql="/Users/michael/Desktop/Reports/opt/src/mysql-connector-c-6.1.11-src.tar.gz"

path_output=${path_base}/bld/$build_type

mkdir -p ${path_opt}/bld

    path_xcode=$( xcode-select -print-path )

for arc in $archs
do
  sdk_type="iphoneos"
  display_type=""
  case "${arc}" in
    "i386"|"x86_64")
        sdk_type="iphonesimulator"
        display_type="$arch"
        ;;
    "arm64"|"arm64e")
        sdk_type="iphoneos"
        display_type="arm"
        ;;
     *)
        sdk_type="iphoneos"
        display_type="$arch"
        ;;
  esac

env_cross_top="${path_xcode}/Platforms/iPhoneOS.platform/Developer"
env_cross_sdk="SDKs/iPhoneOS.sdk"
env_build_tools="${path_xcode}"
env_cc="\"$( xcode-select -print-path )/usr/bin/gcc\" -arch ${ARCH} "

export CROSS_TOP="${env_cross_top}"
export CROSS_SDK="${env_cross_sdk}"
export BUILD_TOOLS="${env_build_tools}"
export CC="${env_cc}"

  path_sdk=$( path_sdk_for_sdk $sdk_type )

export DEVROOT="${platform_root}/Developer"
export SDKROOT=$( xcodebuild -version -sdk $sdk Path 2>/dev/null )
export LD=$( xcrun -find ld )
export LDFLAGS="-arch ${ARCH} -L${SDKROOT}/usr/lib -miphoneos-version-min=8.0 "
    export RANLIB="\"${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib\""

    developer_root=$( xcode-select -print-path )
    platform_root=$( xcodebuild -version -sdk $sdk PlatformPath 2>/dev/null )

  build_path=$path_bld_root/libmysql/$build_type/$sdk_type/$arch

  lib_mysqlclient+=("${build_path}/libmysqlclient.a")
  lib_clientlib+=("${build_path}/libclientlib.a")

  cd $path_project_directory

  export VALID_ARCHS="$archs"
  export ONLY_ACTIVE_ARCH=NO

printf "\n%s\n" "$formatting_divider"
printf "Extracting MySQL source code.\n"
rm -rf -- "${path_build_root}/mysql-connector-c-6.1.11-src"
mkdir -p "${path_build_root}/mysql-connector-c-6.1.11-src"
tar zxf ${path_media_mysql} -C "${path_build_root}"

cd "${path_build_root}/mysql-connector-c-6.1.11-src"

cmake -Wno-dev -GXcode -DCMAKE_CROSSCOMPILING="TRUE" -DCFLAGS="-isysroot $env_cross_top" -DLDFLAGS="-isysroot $env_cross_top -Wl,-syslibroot,$env_cross_top" -DCMAKE_SYSTEM_PROCESSOR="x86_64" -DCMAKE_SYSTEM="Darwin-15.6.0" -DIPHONEOS_DEPLOYMENT_TARGET=12.2 -DCMAKE_OSX_SYSROOT="${path_sdk}" -WITH_SSL="/Users/michael/Desktop/Reports/opt/lib/openssl"

  xcodebuild clean -arch $arc -sdk $path_sdk -configuration $build_type -project $path_project -target zlib
  xcodebuild build -arch $arc -sdk $path_sdk -configuration $build_type -project $path_project -target zlib

xcodebuild clean -arch $arc -sdk $path_sdk -configuration $build_type -project $path_project -target yassl
xcodebuild build -arch $arc -sdk $path_sdk -configuration $build_type -project $path_project -target yassl

xcodebuild clean -arch $arc -sdk $path_sdk -configuration $build_type -project $path_project -target vio
xcodebuild build -arch $arc -sdk $path_sdk -configuration $build_type -project $path_project -target vio

xcodebuild clean -arch $arc -sdk $path_sdk -configuration $build_type -project $path_project -target taocrypt
xcodebuild build -arch $arc -sdk $path_sdk -configuration $build_type -project $path_project -target taocrypt

xcodebuild clean -arch $arc -sdk $path_sdk -configuration $build_type -project $path_project -target mysqlclient
xcodebuild build -arch $arc -sdk $path_sdk -configuration $build_type -project $path_project -target mysqlclient

#xcodebuild build VALID_ARCHS="${archs}" -arch $display_type -sdk $path_sdk -configuration $build_type -project $path_project -target mysqlclient

#printf "mkdir -p" "${build_path}"
printf "mkdir -p" "${path_build_root}${build_path}"
mkdir -p "${path_build_root}${build_path}"
  cp ${path_project_directory}/libmysql/${build_type}-${sdk_type}/libmysqlclient.a ${build_path}/.
  cp ${path_project_directory}/libmysql/${build_type}-${sdk_type}/libclientlib.a ${build_path}/.

exit 1

done

set -o xtrace
if [ ${#lib_mysqlclient} -gt 0 ]; then
  lipo -create ${lib_mysqlclient[@]} -output "${path_output}/libmysqlclient.a"
  lipo -create ${lib_clientlib[@]} -output "${path_output}/libclientlib.a"
fi

#lipo -create libmysql/Release-iphoneos/libmysqlclient.a libmysql/Release-iphonesimulator/libmysqlclient.a -output ./Release/libmysqlclient.a
#lipo -create libmysql/Release-iphoneos/libmysqlclient.a libmysql/Release-iphonesimulator/libclientlib.a -output ./Release/libclientlib.a

#lipo -create libmysql/Debug-iphoneos/libmysqlclient.a libmysql/Debug-iphonesimulator/libmysqlclient.a -output ./Debug/libmysqlclient.a
#lipo -create libmysql/Debug-iphoneos/libmysqlclient.a libmysql/Debug-iphonesimulator/libclientlib.a -output ./Debug/libclientlib.a

exit 0

