#!/bin/sh

#  build_tds.sh
#  MADTdsClient
#
#  Created by Michael on 9/19/16.
#  Copyright © 2016 Everyday Apps LLC. All rights reserved.

set -e

readonly version_freetds="0.91"
readonly version_unixodbc="2.3.2"

readonly version_ios_min="9.3"

platform="iphoneos"

readonly name_freetds="freetds"
readonly name_unixodbc="unixodbc"

readonly name_freetds_stylized="freetds"
readonly name_unixodbc_stylized="unixODBC"

readonly archive_unixodbc_base_url="ftp://ftp.${name_unixodbc}.org/pub/${name_unixodbc_stylized}/"
readonly archive_name_unixodbc="${name_unixodbc_stylized}-${version_unixodbc}"
readonly archive_unixodbc="${archive_name_unixodbc}.tar.gz"

readonly archive_freetds_base_url="ftp://ftp.${name_freetds}.org/pub/${name_freetds_stylized}/stable/"
readonly archive_name_freetds="${name_freetds_stylized}-${version_freetds}"
readonly archive_freetds="${archive_name_freetds}.tar.gz"

readonly path_base=$( pwd )

readonly true=0
readonly false=1

show_help=$false

DEVELOPER=`xcode-select -print-path`
DIR_PROJ=${PROJECT_DIR}
DIR_BLD="$(dirname ${DIR_PROJ})"
DIR_ROOT="$(dirname ${DIR_BLD})"
DIR_LIB=${PROJECT_DIR}/lib

DIR_LIB_ODBC=${PROJECT_DIR}/lib/${archive_name_unixodbc}
DIR_LIB_TDS=${PROJECT_DIR}/lib/${archive_name_freetds}

printf "DEVELOPER        (%s)\n" "${DEVELOPER}"
printf "DIRECTORY build: (%s)\n" "${DIR_BLD}"
printf "DIRECTORY root:  (%s)\n" "${DIR_ROOT}"

FSHORTCUT_ODBC=${DIRLIB}/${name_unixodbc_stylized}.short
FSHORTCUT_TDS=${DIRLIB}/${name_freetds_stylized}-${ARCH}.short

if [ -f $FSHORTCUT_ODBC ]; then
  printf "SKIPPING ODBC.\n"
  build_unixodbc=$false
else
  printf "REQUIRING ODBC.\n"
  build_unixodbc=$true
fi

if [ -f $FSHORTCUT_TDS ]; then
  printf "SKIPPING TDS.\n"
  build_tds=$false
else
  printf "REQUIRING TDS.\n"
  build_tds=$true
fi

counter_arch=0

readonly config_debug="Debug"
readonly config_release="Release"
readonly command_lipo_create="lipo -create "

#
# Globals
#

readonly platform_iphoneos="iphoneos"
readonly platform_simulator="iphonesimulator"
readonly platform_macosx="macosx"

readonly platforms="${platform_iphoneos} ${platform_simulator} ${platform_macosx}"

readonly path_xcode=$( xcode-select -print-path )

readonly archs="armv7 arm64 armv7s x86_64"
readonly archs_macosx="x86_64"
readonly archs_ios="armv7 armv7s arm64"
readonly archs_valid="${archs_macosx} ${archs_ios}"

readonly path_media="${path_base}/media"
readonly path_source="${path_base}/source"
readonly path_library="${path_base}/library"

readonly path_build="${path_base}/build"
readonly path_build_tds="${path_build}/tds"
readonly path_build_unixodbc="${path_build}/unixodbc"

readonly path_media_tds="${path_media}/${archive_freetds}"
readonly path_media_unixodbc="${path_media}/${archive_unixodbc}"

readonly path_source_tds="${path_source}/${archive_name_freetds}"
readonly path_source_unixodbc="${path_source}/${archive_name_unixodbc}"

readonly additional_config_blank="--empty-config=remove"

readonly path_gcc=$( xcrun -find gcc )
readonly path_clang=$( xcrun -find clang )

formatting_divider="####################"
formatting_divider=$formatting_divider$formatting_divider$formatting_divider$formatting_divider

path_sdk_root_iPhoneOS=$( xcodebuild -version -sdk iphoneos Path 2>/dev/null )
path_sdk_root_iPhoneSimulator=$( xcodebuild -version -sdk iphonesimulator Path 2>/dev/null )
path_sdk_root_MacOSX=$( xcodebuild -version -sdk macosx Path 2>/dev/null )

#
# Commands list
#

###
# returns a strong to stdout...
#   no debugging statements.
version_for_platform() {
    local plat=$1
    local version=$( xcodebuild -version -sdk "${plat}" SDKVersion 2>/dev/null )
    echo $version
}

spinner() {
   local pid=$1
   local delay=0.66
   local spinstr='|/-\'
   while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
      local temp=${spinstr#?}
      local s=$(printf " [%c]  " "$spinstr")
      printf "%s" "$s"
      local spinstr=$temp${spinstr%"$temp"}
      sleep $delay
      printf "\b\b\b\b\b\b"
   done
   printf "    \b\b\b\b"
}

platform_for_architecture() {
   local architecture=$1
   local result="iPhoneOS"
   if [[ "${architecture}" == "i386" || "${architecture}" == "x86_64" ]];
   then
      result="iPhoneSimulator"
   fi
   echo $result
}


download_archive() { # $1=archive name; $2=archive url
   if [ ! -e media/${1} ]; then
      printf "\n\nDOWNLOADING %s from %s.\n" "${1}" "${2}"
      cd media && { curl -L -O ${2}${1} ; cd - ; }
   fi
}

extract_source() {
    local archive=$1
    local destination=$2
    printf "EXTRACTING %s\n\t\tto %s.\n" "${archive}" "${destination}"
    rm -Rf -- "${destination}"
    mkdir -p "${destination}"
    tar zxf ${archive} -C ${destination}
}

empty_directory() {
    local DIR=$1
    printf "EMPTYING directory   (%s)\n" "${DIR}"
    printf "MAKE directory       (%s)\n" "${DIR}"
    mkdir -p "${DIR}"

    printf "REMOVE directory     (%s)\n" "${DIR}"
    rm -Rf -- "${DIR}"

    printf "MAKE directory again (%s)\n" "${DIR}"
    mkdir -p "${DIR}"
}

config_make_install() { # $1=sdk-version $2=sdk-min-version $3=arch $4=additional_config $5=path_make

    printf "\n*******************************************\n"
    printf "CONFIG_make_install\n"

    local version_sdk=$1
    local version_sdk_min=$2
    local architecture=$3
    local additional_config=$4
    local path_make=$5
    local log=$6
    local additional_work=$7

    printf "%s\t\t%s\n" "ARCHITECTURE     " $architecture
    printf "%s\t\t%s\n" "ADDITIONAL_config" $additional_config
    printf "%s\t\t%s\n" "PATH_make        " $path_make
    printf "%s\t\t%s\n" "LOG              " $log
    printf "%s\t\t%s\n" "ADDITIONAL_work  " $additional_work

    if [[ "${#additional_config}" > 0 ]];
    then
        s="s/${additional_config_blank}//g"
        additional_config=$(echo $additional_config | sed -e $s)
        printf "ADDITIONAL config is blank (%s)\n" $additional_config
    else
        printf "PASS additional_config_blank for additional_config\n"
        exit 1
    fi

   local architecture_host_part=$( uname -p )
   local architecture_host="${architecture_host_part}-apple-darwin"

   if [[ "${architecture}" == "i386" || "${architecture}" == "x86_64" ]];
   then
      local sdk="iphonesimulator${version_sdk}"
      local architecture_target="${architecture_host_part}-apple-darwin"
   else
      local sdk="iphoneos${version_sdk}"

      if [[ "${architecture}" == "armv7" ]];
      then
         local architecture_target="${architecture}-apple-darwin"
      elif [[ "${architecture}" == "arm64" ]];
      then
         local architecture_target="arm-apple-darwin"
      else
         local architecture_target="${architecture}-apple-darwin"
      fi

   fi

   developer_root=$( xcode-select -print-path )
   platform_root=$( xcodebuild -version -sdk $sdk PlatformPath 2>/dev/null )

   export DEVROOT="${platform_root}/Developer"
   export SDKROOT=$( xcodebuild -version -sdk $sdk Path 2>/dev/null )
   export CC=$( xcrun -find gcc )
   export CFLAGS=" -arch ${architecture} -isysroot ${SDKROOT} -I${SDKROOT}/usr/include -miphoneos-version-min=${version_sdk_min} ${CFLAGS} "
   export CPPFLAGS=" -arch ${architecture} -isysroot ${SDKROOT} -I${SDKROOT}/usr/include ${CPPFLAGS} "
   export LD=$( xcrun -find ld )
   export LDFLAGS="-arch ${architecture} -isysroot ${SDKROOT} -L${SDKROOT}/usr/lib -miphoneos-version-min=${version_sdk_min} "

    printf "SDK version          %s.\n" "${version_sdk}"
    printf "SDK min version      %s.\n" "${version_sdk_min}"
    printf "ARCHITECTURE         %s.\n" "${architecture}"
    printf "ARCHITECTURE host    %s.\n" "${architecture_host}"
    printf "ARCHITECTURE target  %s.\n" "${architecture_target}"
    printf "PREFIX               %s.\n" "${path_make}"
    printf "LOG file             %s.\n" "${log}"
    printf "ADDITIONAL config    %s.\n" "${additional_config}"
    printf "CFLAGS               %s.\n" "${CFLAGS}"
    printf "CPPFLAGS             %s.\n" "${CPPFLAGS}"

   if [[ "${#additional_config}" > 0 ]];
   then
        printf "Performing additional config\n"
        additional_config=$(echo $additional_config | sed -e "s/--/\ --/g")
        pwd
        ./configure --host=${architecture_target} --build=${architecture_host} --target=${architecture_target} --enable-static --disable-shared --prefix="${path_make}" ${additional_config} >> "${log}.error.log" &
        wait $!
   else
        printf "Skipping additional config\n"
      ./configure --host=${architecture_target} --build=${architecture_host} --target=${architecture_target} --enable-static --disable-shared --prefix="${path_make}" >> "${log}.error.log" &
      wait $!

   fi

   if [[ "${#additional_work}" > 0 ]];
   then
        printf "DOING Extra Work\n"
        printf "%s %s" ${additional_work} "${path_make}"
        ${additional_work} "${path_make}"
   fi

    printf "\nMAKE CLEAN"
    make clean >> "${log}.error.log" &
    wait $!

    printf "\nMAKE"
    make  >> "${log}.error.log"
    wait $!

    printf "\nMAKE INSTALL"

    make install >> "${log}.error.log" &
    wait $!

   printf "\n"
}

addtional_work_libsybdb() {
    local path_make=$1
    printf "ADDITIONAL work for libsybdb. $path_make"
    sed -i '' 's/#define HAVE_ICONV 1/#define HAVE_ICONV 0/g' include/config.h
}

#
# Setup
#

readonly version_macosx=$( version_for_platform $platform_macosx )
readonly version_ios=$( version_for_platform $platform_iphoneos )

printf "\n"

printf "MACOS version:   (%s)\n" "${version_macosx}"
printf "IOS version:     (%s)\n" "${version_ios}"

printf "\n"

cd "${path_base}"
mkdir -p $path_media;
mkdir -p $path_library

#
# Download source if it doesn’t exist
#
printf "\nDOWNLOAD archives\n"
download_archive $archive_freetds       $archive_freetds_base_url
download_archive $archive_unixodbc      $archive_unixodbc_base_url

printf "CHANGE directory: %s.\n" "${path_base}"
cd "${path_base}"

#
# UnixODBC
#
# This is not useful on iOS, because its only purpose is to load
#   dynamic libraries.  Dynamic libs are not used on iOS.  Mostly
#   untested.
#
printf "\n\n*******************************************\n"

path_library_unixodbc="${path_library}/UnixODBC"
printf "BUILD if required: ODBC.\n"
if [[ $build_unixodbc == $true && $show_help == $false ]]; then

    printf "\nUNIXODBC\n"

    command_lipo_unixodbc="${command_lipo_create}"

    echo "${archs}"
    for arch in ${archs}
    do

        printf "\n*******************************************\n"
        printf "\nBUILDING UnixODBC for %s %s.\n" "${version_unixodbc}" "${arch}"

        if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
        then
            platform="iPhoneSimulator"
        else
            platform="iPhoneOS"
        fi

        platform=$( platform_for_architecture arch )

        printf "EMPTYING the UnixODBC source code directory.\n"
        empty_directory "${path_source_unixodbc}"

        printf "EXTRACTING UnixODBC source code.\n"
        extract_source $path_media_unixodbc $path_source &
        wait $!

        platform_version_arch="${platform}${version_ios}-${arch}"
        path_build_unixodbc_arch="${path_build_unixodbc}/$platform_version_arch.sdk"

        empty_directory "${path_build_unixodbc_arch}"

        log_build_unixodbc="${path_build_unixodbc}/build-unixodbc-${version_unixodbc}-${arch}.log"
        > "$log_build_unixodbc"

        cd "${path_source_unixodbc}"

        command_lipo_unixodbc="${command_lipo_unixodbc} ${path_build_unixodbc}/libodbc.a"

        additional_config="--libdir=${SDKROOT}/usr/lib "
        additional_config+="--includedir=${SDKROOT}/usr/include "
        additional_config+="--oldincludedir=${SDKROOT}/usr/include "
        additional_config+="--disable-libtool-lock "
        additional_config+="--disable-ltdl-install "
        additional_config+="--enable-gui=no "
        additional_config+="--enable-drivers=yes "
        additional_config+="--enable-drivers-conf=yes "
        additional_config+="--enable-sysconfigdir=Documents/odbc "

        printf "Build path %s.\n" "$path_build_unixodbc_arch"

        printf "config_make_install%s\n"
        #config_make_install $version_ios $version_ios_min $arch $additional_config $path_build_unixodbc_arch $log_build_unixodbc

    done


#rm -rf "${path_library_unixodbc}"
#mkdir -p "${path_library_unixodbc}"

fi

#
# TDS
#
printf "\n\n*******************************************\n"

printf "BUILD if required: TDS.\n"
if [[ $build_tds == $true  && $show_help == $false ]]; then

   set -e

    command_lipo_tds="${command_lipo_create}"
    command_lipo_ct="${command_lipo_create}"
    path_library_tds="${path_library}/libsybdb"

    for arch in ${archs}
    do
        printf "\n*******************************************\n"
        platform=$( platform_for_architecture arch )

        printf "\n\nBUILDING Freetds for %s %s.\n" "${arch}" "${platform}"

        platform_version_arch="${platform}${version_ios}-${arch}"
        path_build_tds_arch="${path_build_tds}/$platform_version_arch.sdk"

        empty_directory "${path_build_tds_arch}"

        log_build_tds="${path_build_tds}/build-tds-${version_freetds}-${arch}.log"
        > "$log_build_tds"

        cd "${path_base}"

        extract_source $path_media_tds $path_source &
        wait $!

        cd "${path_source_tds}"

        command_lipo_tds="${command_lipo_tds} ${path_build_tds_arch}/lib/libsybdb.a"
        command_lipo_ct="${command_lipo_ct} ${path_build_tds_arch}/lib/libct.a"
        additional_config=" -with-tdsver=${version_tds} "
        additional_work="addtional_work_libsybdb"

        printf "VERSION iOS:            %s\n" "${version_ios}"
        printf "VERSION iOS Min:        %s\n" "${version_ios_min}"
        printf "ARCHITECTURE:           %s\n" "${arch}"
        printf "ADDITIONAL Config:      %s\n" "${additional_config}"
        printf "PATH build Tds Arch:    %s\n" "${path_build_tds_arch}"
        printf "LOG path:               %s\n" "${log_build_tds}"
        printf "ADDITIONAL work:        %s\n" "${additional_work}"

        printf "CONFIG_make_install\n"
        # config_make_install $version_ios $version_ios_min
        #   $arch $additional_config $path_build_tds_arch $log_build_tds $additional_work

   done

   #printf "mkdir %s\n" "${path_library_tds}"

   #mkdir -p "${path_library_tds}"
   #rm -rf -- "${path_library_tds}"
   #mkdir -p "${path_library_tds}"

   #printf "cp -R %s\n" "${path_build_tds_arch}/include\" \"${path_library_tds}"

   #cp -R $path_build_tds_arch/include $path_library_tds

   #command_lipo_tds="${command_lipo_tds} -output ${path_library_tds}/libsybdb.a"
   #command_lipo_ct="${command_lipo_ct} -output ${path_library_tds}/libct.a"

   #echo ""
   #echo "${command_lipo_tds}"
   #echo ""
   #echo "${command_lipo_ct}"
   #echo ""

   #$command_lipo_tds
   #$command_lipo_ct

fi


#empty_directory $path_build
#empty_directory $path_source

#echo "Build TDS Complete"
