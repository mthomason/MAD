#!/bin/bash

# Manually download libpng... the host seem unreliable.

#set -o xtrace
set -u

readonly archs="armv7 armv7s arm64 i386 x86_64"

platform_for_architecture() {
   local architecture=$1
   local platform="iPhoneOS"
   if [[ "${architecture}" == "i386" || "${architecture}" == "x86_64" ]];
   then
      platform="iPhoneSimulator"
   fi
  printf "%s\n" $platform
}

opt_config_enable_arm() {
  local architecture=$1
  local additional_config=""
  if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
  then
    platform="iPhoneSimulator"
    additional_config="--enable-arm-neon=no "
  else
    additional_config="--enable-arm-neon=yes "
  fi
  printf "%s\n" $additional_config
}

readonly path_base="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${path_base}"
readonly path_opt_prj="$(dirname "$path_base")"
readonly path_opt="$(dirname "$path_opt_prj")"

readonly prod_name="png"
readonly prod_name_stylized="png"
readonly prod_name_compiled_root="png"
readonly prod_name_compiled_prefix="lib"
readonly prod_default_version_major="1.6"
readonly prod_default_version_minor="25"
readonly version_ios_min="9.3"
readonly prod_url_host="sourcefordge"

readonly path_media="${path_opt}/media"
readonly path_source="${path_opt}/src"
readonly path_library="${path_opt}/lib"
readonly path_bin="${path_opt}/bin"
readonly path_bin_prod="${path_bin}/${prod_name}"
readonly path_build_root="${path_opt}/bld"
readonly prod_name_compiled="$prod_name_compiled_prefix$prod_name_compiled_root"
readonly path_source_product="${path_source}/${prod_name_compiled}"

readonly path_project_share_rel="./../../../usr/local/share"
readonly path_project_share=$( $path_project_share_rel/get-path-absolute $path_project_share_rel )
readonly path_inital="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${path_project_share}"
export PATH="${path_inital}"

readonly true=0
readonly false=1

readonly prod_default_version="${prod_default_version_major}.${prod_default_version_minor}"
readonly prod_version=$prod_default_version
readonly prod_name_library="${prod_name_compiled}.a"

readonly prod_storage_protocol="http"       #https, or ftp
readonly prod_storage_prefix="download"     #https, or ftp
readonly archive_base_url="${prod_storage_protocol}://${prod_storage_prefix}.${prod_url_host}.net/libpng"
readonly archive_name="${prod_name_compiled_prefix}${prod_name_stylized}-${prod_version}"
readonly archive_name_extension="${archive_name}.tar.gz"
readonly archive_url=$archive_base_url/$archive_name_extension

readonly path_media_png="$path_media/$archive_name_extension"

download-archive "${archive_url}" "${path_media}"

readonly path_library_png="${path_library}/png"
readonly path_build="${path_build_root}/libpng"
readonly path_source_png="$path_source/libpng"

config_make_install() { # $1=sdk-version $2=sdk-min-version $3=arch $4=additional_config $5=path_make

  local version_sdk=$1
  local version_sdk_min=$2
  local architecture=$3
  local additional_config=$4
  local path_make=$5
  local log=$6

   local architecture_host_part="x86_64"
   local architecture_host="${architecture_host_part}-apple-darwin"

   if [[ "${architecture}" == "i386" || "${architecture}" == "x86_64" ]];
   then
      local sdk="iphonesimulator${version_sdk}"
      local architecture_target="${architecture_host_part}-apple-darwin"
   else
      local sdk="iphoneos${version_sdk}"

      if [[ "${architecture}" == "armv7" ]];
      then
         local architecture_target="arm-apple-darwin7"
      elif [[ "${architecture}" == "arm64" ]];
      then
         local architecture_target="aarch64-apple-darwin"
      elif [[ "${architecture}" == "armv7s" ]];
      then
         local architecture_target="arm-apple-darwin7s"
      else
         local architecture_target="${architecture}-apple-darwin"
      fi

   fi
  printf "Host: %s\n" "${architecture_target}"

  developer_root=$( xcode-select -print-path )
  platform_root=$( xcodebuild -version -sdk $sdk PlatformPath 2>/dev/null )

  export SDKROOT=$( xcodebuild -version -sdk $sdk Path 2>/dev/null )

  flags_common="-Qunused-arguments "
  flags_common+="-arch $architecture "
  flags_common+="-pipe "
  flags_common+="-no-cpp-precomp "
  flags_common+="-isysroot $SDKROOT "
  flags_common+="-miphoneos-version-min=${version_ios_min} "
  flags_common+="-O2 "
  flags_common+="-fembed-bitcode "

  export CFLAGS="${flags_common}"
  export CPPFLAGS=$CFLAGS
  export CXXFLAGS="$CFLAGS -Wno-deprecated-register"

  make distclean

  pre="${path_library_png}"
  pre_exe="${path_bin_prod}/${architecture}"

  ./configure --prefix="${pre}" --exec-prefix="${pre_exe}" --host=${architecture_target}  --enable-shared=no
  make clean
  make && make install

}

command_lipo_png=""

for arch in ${archs}
do
  mkdir -p "${path_source_product}"
  tar zxf "${path_media}/${archive_name_extension}" -C "${path_source_product}" --strip-components 1

  export PATH="${path_inital}"

  platform=$( platform_for_architecture arch )
  additional_config=$( opt_config_enable_arm arch )

  printf "\n\nBuilding libpng for %s %s." "${arch}" "${platform}"

  xcode_platform=$( cross-platform "${arch}" )
  version_ios=$(xcrun -sdk $xcode_platform --show-sdk-version)

  platform_version_arch="${platform}${version_ios}-${arch}"
  path_build_arch="${path_build}/$platform_version_arch.sdk"

  printf "Extracting libpng source code.\n"
  rm -rf -- "${path_source_png}"
  mkdir -p "${path_source_png}"
  tar zxf ${path_media_png} -C ${path_source_png} --strip-components 1

  platform_version_arch="${platform}${version_ios}-${arch}"
  path_build_unixodbc_arch="${path_build}/$platform_version_arch.sdk"

  log_build_png="${path_build}/build-libpng-${prod_version}-${arch}.log"

  cd "${path_source_png}"
  export CFLAGS=""
  export CPPFLAGS=""

  printf "lipo\n"
  path_lib_arch="${path_bin_prod}/${arch}/lib/libpng.a"
  command_lipo_png+=($path_lib_arch)
  cleanup="${path_bin_prod}/${arch}"
  path_cleanup+=($cleanup)
  printf "Arch path: %s\n" $path_lib_arch
  printf "config_make_install\n\t" "${arch}" "${path_lib_arch}" "${log_build_png}"

  config_make_install $version_ios $version_ios_min $arch "" $path_build_arch $log_build_png

  cd "${path_base}"

done

lipo -create ${command_lipo_png[@]} -output "${path_library_png}/libpng.a"

#for eatme in "${path_cleanup[@]}"
#do
#  delete-directory $eatme
#done
