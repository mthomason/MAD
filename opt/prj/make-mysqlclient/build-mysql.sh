#!/bin/sh
set -o xtrace
export PATH="./../../../usr/local/share:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

readonly path_base=$( pwd )

readonly path_opt_prj="$(dirname "$path_base")"
readonly path_opt="$(dirname "$path_opt_prj")"

readonly prod_name="mysqlconnector"
readonly prod_name_stylized="mysqlconnector"
readonly prod_name_compiled_root="mysqlconnector"
readonly prod_name_compiled_prefix="lib"

readonly path_media="${path_opt}/src"
readonly path_source="${path_opt}/src"
readonly path_library="${path_opt}/lib"
readonly path_build_root="${path_opt}/bld"

build_type="Debug" #"Release"

archs="i386 x86_64 arm64 armv7 armv7s"

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

path_output=${path_project_directory}/$build_type

mkdir -p $path_output

for arch in ${archs}
do
  sdk_type="iphoneos"
  case "${arch}" in
    "i386"|"x86_64")
        sdk_type="iphonesimulator"
        ;;
    "arm64")
        sdk_type="iphoneos"
        ;;
     *)
        sdk_type="iphoneos"
        ;;
  esac

  path_sdk=$( path_sdk_for_sdk $sdk_type )

  build_path=$path_project_directory/libmysql/$build_type/$sdk_type/$arch

  lib_mysqlclient+=("${build_path}/libmysqlclient.a")
  lib_clientlib+=("${build_path}/libclientlib.a")

cd $path_project_directory

  xcodebuild clean VALID_ARCHS="${archs}" -arch $arch -sdk $path_sdk -configuration $build_type -project $path_project -target mysqlclient
  xcodebuild build VALID_ARCHS="${archs}" -arch $arch -sdk $path_sdk -configuration $build_type -project $path_project -target taocrypt
  xcodebuild build VALID_ARCHS="${archs}" -arch $arch -sdk $path_sdk -configuration $build_type -project $path_project -target mysqlclient

  mkdir -p $build_path
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

