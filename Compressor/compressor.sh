#!/bin/sh

#  buildcounter.sh
#  MAD
#
#  Created by Michael Thomason on 1/24/14.
#  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.

set -e

readonly path_base=$( pwd )

readonly true=0
readonly false=1

case $path_base in # Check if current path contains whitespace.
   *\ * )
   printf "ABORT: Current path has whitespace.\n"
   exit 1
   ;;
   esac

print_help() {
   printf "  %s\n"  "Usage: compressor [options] ..."
   printf "  %s\n" "--libffi                 Build Libffi.\n"
   printf "  %s\n" "--glib                   Build Glib.\n"
   printf "  %s\n" "--gettext                Build Gettext.\n"
   printf "  %s\n" "--acl                    Build Gettext.\n"
#printf "  %s\n" "--attr                   Build Gettext.\n"
   printf "  %s\n" "--classpath              Build Classpath.\n"
   printf "  %s\n" "--openssl                Build OpenSSL.\n"
   printf "  %s\n" "--freetds                Build FreeTds.\n"
   printf "  %s\n" "--libpng                 Build libpng.\n"
   printf "  %s\n" "--mysql                  Build MySQL Connector.\n"
   printf "  %s\n" "-h,--help                Show help.\n"
#  printf "  %s\n" "--autoconf               Build Autoconf.\n" #Only needed on local machine
#  printf "  %s\n" "--automake               Build Automake.\n" #Only needed on local machine
#  printf "  %s\n" "--unixodbc               Build UnixODBC.\n" #Not useful on iOS, becuase dynamic loading
}

build_openssl=$false
build_png=$false
build_mysql=$false
build_mysql_ios7=$false
build_tds=$false
build_zint=$false
build_unixodbc=$false
build_glib=$false
build_classpath=$false
build_autoconf=$false
build_automake=$false
build_libffi=$false
build_gettext=$false
build_attr=$false
build_gettext=$false
show_help=$false

#
# Process flags
#


if [[ $# == 0 ]];
then
   show_help=$true
else
   show_help=$false
fi

while [[ $# > 0 ]]
do
    key="$1"
    shift

    case $key in

        --acl)
            build_acl=$true;;

        --attr)
            build_attr=$true;;

        --gettext)
            build_gettext=$true;;

        --libffi)
            build_libffi=$true;;

        --autoconf)
            build_autoconf=$true;;

        --automake)
            build_automake=$true;;

        --glib)
            build_glib=$true;;

        --classpath)
            build_classpath=$true;;

      #don't build unixodbc for iOS, lol
        --unixodbc)
            build_unixodbc=$false;;

        --openssl)
            build_openssl=$true;;

        --libpng)
            build_png=$true;;

        --mysqlold)
            build_mysql=$true;;

        --mysql)
            build_mysql_ios7=$true;;

        --freetds)
            build_tds=$true;;

        --zint)
            build_zint=$true;;

        --help | -h)
            show_help=$true;;

        esac
done

if [ $show_help == $true ];
then
    print_help
    exit 0
fi

version_for_platform() {
    local version=$( xcodebuild -version -sdk "${1}" SDKVersion 2>/dev/null )
    printf "%s" "${version}"
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

print_building() {
   printf "Building %s version %s for architecture %s.\n" "$1" "$2" "$3"
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
      printf "\n\nDownloading %s from %s.\n" "${1}" "${2}"
      cd media && { curl -L -O ${2}${1} ; cd - ; }
   fi
}

extract_source() {
    local archive=$1
    local destination=$2
    printf "Extracting %s\n\t\tto %s.\n" $archive $destination
    rm -rf -- "${destination}"
    mkdir -p "${destination}"
    tar zxf ${archive} -C ${destination}
}

empty_directory() {
    local directory=$1
    mkdir -p "${directory}"
    rm -rf -- "${directory}"
    mkdir -p "${directory}"
}

#
# Globals
#

readonly version_openssl="1.0.1g”
readonly version_mysql="6.1.3"
readonly version_freetds="0.91"
readonly version_tds=7.1
readonly version_zint="2.4.2"
readonly version_png="1.6.10"
readonly version_unixodbc="2.3.2"
readonly version_classpath="0.98"
readonly version_glib="2.38.2"
readonly version_autoconf="2.69"
readonly version_automake="1.14"
readonly version_gettext="0.18.3.1"
readonly version_libffi="3.0.14RC0"
readonly version_acl="2.2.52"
readonly version_attr="2.4.47"

readonly version_mysql_6_0="6.0.2"  #do not change
readonly version_mysql_6_1="6.1.3"

readonly platform_iphoneos="iphoneos"
readonly platform_simulator="iphonesimulator"
readonly platform_macosx="macosx"

readonly platforms="${platform_iphoneos} ${platform_simulator} ${platform_macosx}"

readonly path_xcode=$( xcode-select -print-path )

readonly version_macosx=$( version_for_platform $platform_macosx )
readonly version_ios=$( version_for_platform $platform_iphoneos )

readonly version_ios_min="6.0"

readonly sdk_iphoneos="${platform_iphoneos}${version_ios}"
readonly sdk_simulator="${platform_simulator}${version_ios}"

readonly archs="armv7 armv7s arm64 i386 x86_64"
#readonly archs="arm64 x86_64"
readonly archs_macosx="i386 x86_64"
readonly archs_ios="armv7 armv7s arm64"
readonly archs_valid="${archs_macosx} ${archs_ios}"

readonly archive_openssl_base_url="http://www.openssl.org/source/"
readonly archive_name_openssl="openssl-${version_openssl}"
readonly archive_openssl="${archive_name_openssl}.tar.gz"

readonly archive_autoconf_base_url="http://ftp.gnu.org/gnu/autoconf/"
readonly archive_name_autoconf="autoconf-${version_autoconf}"
readonly archive_autoconf="${archive_name_autoconf}.tar.gz"

readonly archive_automake_base_url="http://ftp.gnu.org/gnu/automake/"
readonly archive_name_automake="automake-${version_automake}"
readonly archive_automake="${archive_name_automake}.tar.gz"

readonly archive_glib_base_url="https://git.gnome.org/browse/glib/snapshot/"
readonly archive_name_glib="glib-${version_glib}"
readonly archive_glib="${archive_name_glib}.tar.gz"

readonly archive_mysql_base_url="http://dev.mysql.com/get/Downloads/Connector-C/"
if [[ "${version_mysql}" == "${version_mysql_6_0}" ]]
then
   readonly archive_name_mysql="mysql-connector-c-${version_mysql}"
else
   readonly archive_name_mysql="mysql-connector-c-${version_mysql}-src"
fi
readonly archive_mysql="${archive_name_mysql}.tar.gz"

readonly archive_unixodbc_base_url="ftp://ftp.unixodbc.org/pub/unixODBC/"
readonly archive_name_unixodbc="unixODBC-${version_unixodbc}"
readonly archive_unixodbc="${archive_name_unixodbc}.tar.gz"

readonly archive_classpath_base_url="ftp://ftp.gnu.org/gnu/classpath/"
readonly archive_name_classpath="classpath-${version_classpath}"
readonly archive_classpath="${archive_name_classpath}.tar.gz"

readonly archive_freetds_base_url="ftp://ftp.freetds.org/pub/freetds/stable/"
readonly archive_name_freetds="freetds-${version_freetds}"
readonly archive_freetds="freetds-stable.tgz"

readonly archive_zint_base_url="https://github.com/downloads/zint/zint/"
readonly archive_name_zint="zint-${version_zint}"
readonly archive_zint="${archive_name_zint}.tar.gz"

readonly archive_png_base_url="ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/"
readonly archive_name_png="libpng-${version_png}"
readonly archive_png="${archive_name_png}.tar.gz"

readonly path_media="$path_base/media"
readonly path_source="$path_base/source"
readonly path_library="$path_base/library"

readonly path_build="${path_base}/build"
readonly path_build_openssl="${path_build}/openssl"
readonly path_build_mysql="${path_build}/mysqlclient"
readonly path_build_zint="${path_build}/zint"
readonly path_build_tds="${path_build}/tds"
readonly path_build_png="${path_build}/libpng"
readonly path_build_unixodbc="${path_build}/unixodbc"
readonly path_build_classpath="${path_build}/classpath"
readonly path_build_glib="${path_build}/glib"
readonly path_build_autoconf="${path_build}/autoconf"
readonly path_build_automake="${path_build}/automake"

readonly path_media_ssl="$path_media/$archive_openssl"
readonly path_media_mysql="$path_media/$archive_mysql"
readonly path_media_tds="$path_media/$archive_freetds"
readonly path_media_zint="$path_media/$archive_zint"
readonly path_media_png="$path_media/$archive_png"
readonly path_media_unixodbc="$path_media/$archive_unixodbc"
readonly path_media_classpath="$path_media/$archive_classpath"
readonly path_media_glib="$path_media/$archive_glib"
readonly path_media_autoconf="$path_media/$archive_autoconf"
readonly path_media_automake="$path_media/$archive_automake"

readonly additional_config_blank="--empty-config=remove"

readonly path_gcc=$( xcrun -find gcc )
readonly path_clang=$( xcrun -find clang )

formatting_divider="####################"
formatting_divider=$formatting_divider$formatting_divider$formatting_divider$formatting_divider

path_sdk_root_iPhoneOS=$( xcodebuild -version -sdk iphoneos Path 2>/dev/null )
path_sdk_root_iPhoneSimulator=$( xcodebuild -version -sdk iphonesimulator Path 2>/dev/null )
path_sdk_root_MacOSX=$( xcodebuild -version -sdk macosx Path 2>/dev/null )

addtional_work_libsybdb() {
    local path_make=$1
    printf "Additional work for libsybdb. $path_make"
    sed -i '' 's/#define HAVE_ICONV 1/#define HAVE_ICONV 0/g' include/config.h
}


config_make_install() { # $1=sdk-version $2=sdk-min-version $3=arch $4=additional_config $5=path_make

   local version_sdk=$1
   local version_sdk_min=$2
   local architecture=$3
   local additional_config=$4
   local path_make=$5
   local log=$6
   local additional_work=$7

    if [[ "${#additional_config}" > 0 ]];
    then
        s="s/${additional_config_blank}//g"
        additional_config=$(echo $additional_config | sed -e $s)
        printf "Additional config is blank (%s)" $additional_config
    else
        echo "pass additional_config_blank for additional_config"
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

   export DEVROOT="${platform_root}/Developer "
   export SDKROOT=$( xcodebuild -version -sdk $sdk Path 2>/dev/null )
   export CC=$( xcrun -find gcc )
   export CFLAGS=" -arch ${architecture} -isysroot ${SDKROOT} -I${SDKROOT}/usr/include -miphoneos-version-min=${version_sdk_min} ${CFLAGS} "
   export CPPFLAGS=" -arch ${architecture} -isysroot ${SDKROOT} -I${SDKROOT}/usr/include ${CPPFLAGS} "
   export LD=$( xcrun -find ld )
   export LDFLAGS="-arch ${architecture} -isysroot ${SDKROOT} -L${SDKROOT}/usr/lib -miphoneos-version-min=${version_sdk_min} "

    printf "Configure with sdk version          %s.\n" "${version_sdk}"
    printf "Configure with sdk min version      %s.\n" "${version_sdk_min}"
    printf "Configure with architecture         %s.\n" "${architecture}"
    printf "Configure with architecture host    %s.\n" "${architecture_host}"
    printf "Configure with architecture target  %s.\n" "${architecture_target}"
    printf "Configure with prefix               %s.\n" "${path_make}"
    printf "Configure with log file             %s.\n" "${log}"
    printf "Configure with additional config    %s.\n" "${additional_config}"
    printf "Configure with CFLAGS               %s.\n" "${CFLAGS}"
    printf "Configure with CPPFLAGS             %s.\n" "${CPPFLAGS}"

   if [[ "${#additional_config}" > 0 ]];
   then

        additional_config=$(echo $additional_config | sed -e "s/--/\ --/g")
        pwd
        ./configure --host=${architecture_target} --build=${architecture_host} --target=${architecture_target} --enable-static --disable-shared --prefix="${path_make}" ${additional_config} >> "${log}.error.log" &
        spinner $!
   else

      ./configure --host=${architecture_target} --build=${architecture_host} --target=${architecture_target} --enable-static --disable-shared --prefix="${path_make}" >> "${log}.error.log" &
      spinner $!

   fi

   if [[ "${#additional_work}" > 0 ]];
   then
        ${additional_work} "${path_make}"
   fi

    printf "make clean"
    make clean >> "${log}.error.log" &
    spinner $!

    printf "\nmake\n"
    make -j8 >> "${log}.error.log"
    spinner $!

    printf "\nmake install"

    make -j8 install >> "${log}.error.log" &
    spinner $!

   printf "\n"

}

path_source_openssl="$path_source/$archive_name_openssl"
path_source_mysql="$path_source/$archive_name_mysql"
path_source_tds="$path_source/$archive_name_freetds"
path_source_zint="$path_source/$archive_name_zint"
path_source_png="$path_source/$archive_name_png"
path_source_unixodbc="$path_source/$archive_name_unixodbc"
path_source_classpath="$path_source/$archive_name_classpath"
path_source_glib="$path_source/$archive_name_glib"
path_source_autoconf="$path_source/$archive_name_autoconf"
path_source_automake="$path_source/$archive_name_automake"
path_source_autoconf="$path_source/$archive_name_acl"
path_source_automake="$path_source/$archive_name_attr"

mkdir -p media;

#
# Download source if it doesn’t exist
#

download_archive $archive_glib      $archive_glib_base_url
download_archive $archive_classpath $archive_classpath_base_url
download_archive $archive_openssl   $archive_openssl_base_url
download_archive $archive_mysql     $archive_mysql_base_url
download_archive $archive_freetds   $archive_freetds_base_url
download_archive $archive_zint      $archive_zint_base_url
download_archive $archive_png       $archive_png_base_url

cd "${path_base}"

rm -rf -- source
mkdir -p source
mkdir -p library

counter_arch=0

platform="iphoneos"

readonly config_debug="Debug"
readonly config_release="Release"
readonly command_lipo_create="lipo -create "

#
# Gettext - Required by Glib
#   Unused way to (maybe) cross compile gettext.  Why?  Becuse, fuck it.
#

build_gettext_static_ios() {

    readonly archive_gettext_base_url="http://ftp.gnu.org/pub/gnu/gettext/"
    readonly archive_name_gettext="gettext-${version_gettext}"
    readonly archive_gettext="${archive_name_gettext}.tar.gz"
    readonly path_source_gettext="$path_source/$archive_name_gettext"
    readonly path_media_gettext="$path_media/$archive_gettext"
    readonly path_build_gettext="${path_build}/gettext"

    download_archive $archive_gettext $archive_gettext_base_url

    echo "Building gettext."

    local command_lipo_gettext_libintl="${command_lipo_create}"
    local command_lipo_gettext_libgettextpo="${command_lipo_create}"
    local command_lipo_gettext_libasprintf="${command_lipo_create}"

    for arch in ${archs}
    do

        platform=$( platform_for_architecture arch )

        platform_version_arch="${platform}${version_ios}-${arch}"
        path_build_gettext_arch="${path_build_gettext}/$platform_version_arch.sdk"

        mkdir -p "${path_build_gettext_arch}"
        rm -rf -- "${path_build_gettext_arch}"
        mkdir -p "${path_build_gettext_arch}"
        tar zxf ${path_media_gettext} -C ${path_build_gettext_arch}

        log_build_gettext="${path_build_gettext_arch}/build-gettext-${version_gettext}-${arch}.log"
        > "$log_build_gettext"

        prepp="${path_build_gettext}/$platform_version_arch.sdk/${archive_name_gettext}"
        cd "${prepp}"

        extract_source $path_media_gettext $path_build_gettext_arch &
        spinner $!

        cd "${prepp}"

        additional_config="--enable-gui=no "

        printf "Build path %s.\n" "$path_build_gettext_arch"
        printf "Build conf %s.\n" "$additional_config"
        printf "Build arch %s.\n" "$arch"
        printf "Build log  %s.\n" "$log_build_gettext"

        export CFLAGS=" -I${path_library}/crt_externs "
        export CPPFLAGS=" -I${path_library}/crt_externs "

        config_make_install $version_ios $version_ios_min $arch $additional_config $prepp $log_build_gettext

        command_lipo_gettext_libintl="$command_lipo_gettext_libintl $prepp/lib/libintl.a";
        command_lipo_gettext_libgettextpo="$command_lipo_gettext_libgettextpo $prepp/lib/libgettextpo.a";
        command_lipo_gettext_libasprintf="$command_lipo_gettext_libasprintf $prepp/lib/libasprintf.a";
    done

    local path_library_gettext="${path_library}/gettext"

    empty_directory $path_library_gettext
    empty_directory "$path_library_gettext/include"

    cp -R "$path_build_gettext/$platform_version_arch.sdk/$archive_name_gettext/include/." "$path_library_gettext/include/."

    command_lipo_gettext_libintl="$command_lipo_gettext_libintl -output $path_library_gettext/libintl.a";
    command_lipo_gettext_libgettextpo="$command_lipo_gettext_libgettextpo -output $path_library_gettext/libgettextpo.a";
    command_lipo_gettext_libasprintf="$command_lipo_gettext_libasprintf -output $path_library_gettext/libasprintf.a";

    echo $command_lipo_gettext_libintl
    echo $command_lipo_gettext_libgettextpo
    echo $command_lipo_gettext_libasprintf

    $command_lipo_gettext_libintl
    $command_lipo_gettext_libgettextpo
    $command_lipo_gettext_libasprintf

}

if [[ $build_gettext == $true && $show_help == $false ]]; then
    build_gettext_static_ios
fi


#
# Libffi - Required by Glib
#

build_libffi_static_ios() {

    printf "Building Libffi.\n"
    printf "Requries automake, autoconf, and libtool to be installed locally.\n"

    local readonly archive_libffi_base_url="ftp://sourceware.org/pub/libffi/"
    local readonly archive_name_libffi="libffi-${version_libffi}"
    local readonly archive_libffi="${archive_name_libffi}.tar.gz"
    local readonly path_media_libffi="$path_media/$archive_libffi"
    local readonly path_source_libffi="$path_source/$archive_name_libffi"
    local readonly path_library_libffi="${path_library}/libffi"
    local readonly path_build_libffi="${path_build}/libffi"

    download_archive $archive_libffi $archive_libffi_base_url

    #instead of empty, move to tmp...
    empty_directory $path_library_libffi

    local command_lipo_libffi="${command_lipo_create}"

    empty_directory $path_build_libffi

    for platform in $platform_iphoneos $platform_simulator
    do

        if [ "${platform}" == "${platform_iphoneos}" ]
        then
            local readonly config=$config_release
            local readonly sdk_build=${sdk_iphoneos}
            local readonly archs_to_build=$archs_ios
        else
            local readonly config=$config_debug
            local readonly sdk_build=${sdk_simulator}
            local readonly archs_to_build=$archs_macosx
        fi

        local readonly platform_version_arch="${platform}${version_ios}"

        empty_directory $path_source_libffi

        extract_source $path_media_libffi $path_source &
        spinner $!

        local log_build_libffi="${path_build_libffi}/build-libffi-${version_libffi}.log"
        > "$log_build_libffi"
        pushd "${path_source_libffi}" > /dev/null

        xcodebuild -project libffi.xcodeproj -target libffi-iOS -configuration $config -sdk $sdk_build ONLY_ACTIVE_ARCH=NO ARCHS="${archs_to_build}" VALID_ARCHS="${archs_valid}" >> "${log_build_libffi}" &
        spinner $!

        popd > /dev/null
        local readonly archive="${path_build_libffi}/${platform_version_arch}.sdk"
        empty_directory $archive
        mv "$path_source_libffi/build/$config-$platform" $archive
        command_lipo_libffi="$command_lipo_libffi $archive/$config-$platform/libffi.a "

    done

    path_library_libffi_include="$path_library_libffi"
    empty_directory $path_library_libffi_include
    mv "$path_source_libffi/darwin_ios/include" "${path_library_libffi_include}/."
    cp -R "${path_source_libffi}/darwin_common/include/." "${path_library_libffi_include}/include/"

    command_lipo_libffi="$command_lipo_libffi -output $path_library_libffi/libffi.a"
    $command_lipo_libffi

}

if [[ $build_libffi == $true && $show_help == $false ]]; then
    build_libffi_static_ios
fi

#
# Automake - Required by Glib
#   Unused way to (maybe) cross compile automake.  Why?  Becuse, fuck it.
#

path_library_automake="${path_library}/automake"

if [[ $build_automake == $true && $show_help == $false ]]; then

    download_archive $archive_automake  $archive_automake_base_url


    echo "Building Automake."

    command_lipo_automake="${command_lipo_create}"

    for arch in ${archs}
    do

        platform=$( platform_for_architecture arch )

        platform_version_arch="${platform}${version_ios}-${arch}"
        path_build_automake_arch="${path_library_automake}/$platform_version_arch.sdk"

        mkdir -p "${path_build_automake_arch}"
        rm -rf -- "${path_build_automake_arch}"
        mkdir -p "${path_build_automake_arch}"
        tar zxf ${path_media_automake} -C ${path_build_automake_arch}

        log_build_automake="${path_build_automake_arch}/build-automake-${version_automake}-${arch}.log"
        > "$log_build_automake"

        prepp="${path_library}/automake/$platform_version_arch.sdk/${archive_name_automake}"
        cd "${prepp}"

        extract_source $path_media_automake $path_build_automake_arch &
        spinner $!

        cd "${prepp}"

        additional_config="--enable-gui=no "

        printf "Build path %s.\n" "$path_build_automake_arch"
        printf "Build conf %s.\n" "$additional_config"
        printf "Build arch %s.\n" "$arch"
        printf "Build log  %s.\n" "$log_build_automake"

        config_make_install $version_ios $version_ios_min $arch $additional_config $prepp $log_build_automake

    done
fi

#
# Autoconf - Required by Glib
#   Unused way to (maybe) cross compile automake.  Why?  Becuse, fuck it.
#

path_library_autoconf="${path_library}/autoconf"

if [[ $build_autoconf == $true && $show_help == $false ]]; then

    download_archive $archive_autoconf  $archive_autoconf_base_url
    echo "Building Automake."

    command_lipo_autoconf="${command_lipo_create}"

    for arch in ${archs}
    do

        platform=$( platform_for_architecture arch )

        platform_version_arch="${platform}${version_ios}-${arch}"
        path_build_autoconf_arch="${path_library_autoconf}/$platform_version_arch.sdk"

        mkdir -p "${path_build_autoconf_arch}"
        rm -rf -- "${path_build_autoconf_arch}"
        mkdir -p "${path_build_autoconf_arch}"
        tar zxf ${path_media_autoconf} -C ${path_build_autoconf_arch}

        log_build_autoconf="${path_build_autoconf_arch}/build-autoconf-${version_autoconf}-${arch}.log"
        > "$log_build_autoconf"

        prepp="${path_library}/autoconf/$platform_version_arch.sdk/${archive_name_autoconf}"
        cd "${prepp}"

        extract_source $path_media_autoconf $path_build_autoconf_arch &
        spinner $!

        cd "${prepp}"

        additional_config="--enable-gui=no "

        printf "Build path %s.\n" "$path_build_autoconf_arch"
        printf "Build conf %s.\n" "$additional_config"
        printf "Build arch %s.\n" "$arch"
        printf "Build log  %s.\n" "$log_build_autoconf"

        config_make_install $version_ios $version_ios_min $arch $additional_config $prepp $log_build_autoconf

    done
fi

#
# Glib - Required by Classpath
#

path_library_glib="${path_library}/glib"

if [[ $build_glib == $true && $show_help == $false ]]; then

    echo "Building Glib."

    command_lipo_glib="${command_lipo_create}"

    path_pre_glib=$PATH

    for arch in ${archs}
    do

#        if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
#        then
#            platform="iPhoneSimulator"
#        else
#            platform="iPhoneOS"
#        fi

        platform=$( platform_for_architecture arch )
        platform_version_arch="${platform}${version_ios}-${arch}"


        parent=$( dirname $path_base )
        path_pkg_config="${parent}/3rdPartyProjects/pkg-config-0.28"

#        path_autoconf="${path_library}/autoconf/$platform_version_arch.sdk/${archive_name_autoconf}"
#        path_automake="${path_library}/automake/$platform_version_arch.sdk/${archive_name_automake}"
#        path_autoconf="/Users/mthomason/Desktop/Reports/Compressor/library/autoconf/iPhoneOS7.1-i386.sdk/${archive_name_autoconf}"
#        path_automake="/Users/mthomason/Desktop/Reports/Compressor/library/automake/iPhoneOS7.1-i386.sdk/${archive_name_automake}"

#        path_autoconf_bin="${path_autoconf}/bin"
#        path_autoconf_lib="${path_autoconf}/lib"

#        if [ -e "$path_autoconf" ]
#        then
#            printf "\nFound autoconf"
#        else
#            printf "\nMissing %s\n" $path_autoconf
#            printf "Starting build of autoconf.\n\n"
#            exit 1
#            sh ./compressor.sh --autoconf
#        fi

#        path_automake_bin="${path_automake}/bin"
#        path_automake_lib="${path_automake}/lib"

#        if [ -e "$path_automake" ]
#        then
#            printf "\nFound automake"
#        else
#            printf "\nMissing %s\n" $path_automake
#            printf "\nStarting build of automake.\n\n"
#            exit 1
#            sh ./compressor.sh --automake
#        fi

#        echo ""
#        echo "path_pkg_config"
#        echo "${path_pkg_config}"
#        echo ""

#        PATH="${path_autoconf_bin}:${path_pkg_config}:${path_pkg_config}/pkg-config:${path_pkg_config}/glib:${path_automake_bin}:${path_autoconf_lib}:${path_automake_lib}:${path_pre_glib}"
#        export PATH

        printf "Extracting Glib source code.\n"
        rm -rf -- "${path_source_glib}"
        mkdir -p "${path_source_glib}"
        tar zxf ${path_media_glib} -C ${path_source}

        path_build_glib_arch="${path_build_glib}/$platform_version_arch.sdk"

        mkdir -p "${path_build_glib_arch}"
        rm -rf -- "${path_build_glib_arch}"
        mkdir -p "${path_build_glib_arch}"
        log_build_glib="${path_build_glib}/build-glib-${version_glib}-${arch}.log"
        > "$log_build_glib"

        cd "${path_base}"

        extract_source $path_media_glib $path_source &
        spinner $!

        cd "${path_source_glib}"
        pwd

        export LIBFFI_CFLAGS="-I${path_library}/libffi/include"
        export LIBFFI_LIBS="-L${path_library}/libffi -lffi"

        sh ./autogen.sh

        echo "Autoget success"
        echo exit 0

        additional_config="--enable-gui=no "


#SDKROOT=$( xcodebuild -version -sdk $sdk Path 2>/dev/null )
#echo $SKDROOT
#command_lipo_unixodbc="${command_lipo_classpath} ${path_build_classpath}/libjvm.a"
#       additional_config="--libdir=${SDKROOT}/usr/lib--includedir=${SDKROOT}/usr/include--oldincludedir=${SDKROOT}/usr/include--disable-libtool-lock--disable-ltdl-install--enable-gui=no--enable-drivers=yes--enable-drivers-conf=yes--enable-sysconfigdir=Documents/odbc "
#additional_config="--libdir=${SDKROOT}/usr/lib--includedir=${SDKROOT}/usr/include--oldincludedir=${SDKROOT}/usr/include--cache-file=Library/Caches/odbc--enable-gui=no--enable-drivers=yes--enable-drivers-conf=yes--enable-sysconfigdir=Documents/odbc "


        config_make_install $version_ios $version_ios_min $arch $additional_config $path_build_glib_arch $log_build_glib


    done

fi

#
# Classpath
#
# This is not useful on iOS, because its only purpose is to load
#   dynamic libraries.
#

path_library_classpath="${path_library}/classpath"

if [[ $build_classpath == $true && $show_help == $false ]]; then

    echo "Building Classpath."

    command_lipo_classpath="${command_lipo_create}"

    for arch in ${archs}
    do

    if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
    then
        platform="iPhoneSimulator"
    else
        platform="iPhoneOS"
    fi



    platform=$( platform_for_architecture arch )

    printf "Extracting Classpath source code.\n"
    rm -rf -- "${path_source_classpath}"
    mkdir -p "${path_source_classpath}"
    tar zxf ${path_media_classpath} -C ${path_source}

    platform_version_arch="${platform}${version_ios}-${arch}"
    path_build_classpath_arch="${path_build_classpath}/$platform_version_arch.sdk"

    mkdir -p "${path_build_classpath_arch}"
    rm -rf -- "${path_build_classpath_arch}"
    mkdir -p "${path_build_classpath_arch}"
    log_build_classpath="${path_build_classpath}/build-classpath-${version_classpath}-${arch}.log"
    > "$log_build_classpath"

    cd "${path_base}"

    extract_source $path_media_classpath $path_source &
    spinner $!

    cd "${path_source_classpath}"
    additional_config="--with-internal-glib--with-pkg-config=../3rdPartyProjects/pkg-config-0.28/pkg-config"

#SDKROOT=$( xcodebuild -version -sdk $sdk Path 2>/dev/null )
#echo $SKDROOT
#command_lipo_unixodbc="${command_lipo_classpath} ${path_build_classpath}/libjvm.a"
#       additional_config="--libdir=${SDKROOT}/usr/lib--includedir=${SDKROOT}/usr/include--oldincludedir=${SDKROOT}/usr/include--disable-libtool-lock--disable-ltdl-install--enable-gui=no--enable-drivers=yes--enable-drivers-conf=yes--enable-sysconfigdir=Documents/odbc "
#additional_config="--libdir=${SDKROOT}/usr/lib--includedir=${SDKROOT}/usr/include--oldincludedir=${SDKROOT}/usr/include--cache-file=Library/Caches/odbc--enable-gui=no--enable-drivers=yes--enable-drivers-conf=yes--enable-sysconfigdir=Documents/odbc "

    printf "Build path %s.\n" "$path_build_classpath_arch"

    config_make_install $version_ios $version_ios_min $arch $additional_config $path_build_classpath_arch $log_build_classpath


    done

fi

#
# UnixODBC
#
# This is not useful on iOS, because its only purpose is to load
#   dynamic libraries.  Dynamic libs are not used on iOS.  Mostly
#   untested.
#

path_library_unixodbc="${path_library}/UnixODBC"

if [[ $build_unixodbc == $true && $show_help == $false ]]; then
    echo "Building Unixodbc."
    download_archive $archive_unixodbc  $archive_unixodbc_base_url


    command_lipo_unixodbc="${command_lipo_create}"

    for arch in ${archs}
    do

        print_building "UnixODBC" $version_unixodbc $arch

        if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
        then
            platform="iPhoneSimulator"
        else
            platform="iPhoneOS"
        fi

        platform=$( platform_for_architecture arch )

        printf "Extracting UnixODBC source code.\n"
        rm -rf -- "${path_source_unixodbc}"
        mkdir -p "${path_source_unixodbc}"
        tar zxf ${path_media_unixodbc} -C ${path_source}

        platform_version_arch="${platform}${version_ios}-${arch}"
        path_build_unixodbc_arch="${path_build_unixodbc}/$platform_version_arch.sdk"

        mkdir -p "${path_build_unixodbc_arch}"
        rm -rf -- "${path_build_unixodbc_arch}"
        mkdir -p "${path_build_unixodbc_arch}"
        log_build_unixodbc="${path_build_unixodbc}/build-unixodbc-${version_unixodbc}-${arch}.log"
        > "$log_build_unixodbc"

        cd "${path_base}"

        extract_source $path_media_unixodbc $path_source &
        spinner $!

        cd "${path_source_unixodbc}"

        command_lipo_unixodbc="${command_lipo_unixodbc} ${path_build_unixodbc}/libodbc.a"
        additional_config="--libdir=${SDKROOT}/usr/lib--includedir=${SDKROOT}/usr/include--oldincludedir=${SDKROOT}/usr/include--disable-libtool-lock--disable-ltdl-install--enable-gui=no--enable-drivers=yes--enable-drivers-conf=yes--enable-sysconfigdir=Documents/odbc "
        printf "Build path %s.\n" "$path_build_unixodbc_arch"

        config_make_install $version_ios $version_ios_min $arch $additional_config $path_build_unixodbc_arch $log_build_unixodbc

    done


    rm -rf "${path_library_unixodbc}"
    mkdir -p "${path_library_unixodbc}"

fi

#
# OpenSSL
#

path_library_openssl="${path_library}/openssl"

if [[ $build_openssl == $true && $show_help == $false ]]; then

   command_lipo_libcrypto="${command_lipo_create}"
   command_lipo_libssl="${command_lipo_create}"

   for arch in ${archs}
   do

      print_building "OpenSSL" $version_openssl $arch

      if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
         then
            platform="iPhoneSimulator"
         else
            platform="iPhoneOS"
      fi
      
      env_cross_top="${path_xcode}/Platforms/${platform}.platform/Developer"
      env_cross_sdk="${platform}${version_ios}.sdk"
      env_build_tools="${path_xcode}"
      env_cc="${env_build_tools}/usr/bin/gcc -arch ${arch}"

      export CROSS_TOP="${env_cross_top}"
      export CROSS_SDK="${env_cross_sdk}"
      export BUILD_TOOLS="${env_build_tools}"
      export CC="${env_cc}"

      extract_source $path_media_ssl $path_source

       #
       # Compiling OpenSSL
       #
       cd "${path_source_openssl}"

       if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
          then
             printf ""
           else
             sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
       fi
      
       platform_version_arch="${platform}${version_ios}-${arch}"
       path_build="${path_base}/build"
       path_build_openssl_arch="${path_build}/openssl/${platform_version_arch}.sdk"
       
       path_to_libcrypto="${path_build_openssl_arch}/lib/libcrypto.a"
       path_to_libssl="${path_build_openssl_arch}/lib/libssl.a"

       slibs_libcrypto[counter_arch]="${path_to_libcrypto}"
       slibs_libssl[counter_arch]="${path_to_libssl}"

       command_lipo_libcrypto="${command_lipo_libcrypto} ${path_to_libcrypto}"
       command_lipo_libssl="${command_lipo_libssl} ${path_to_libssl}"

       mkdir -p "${path_build}"
       mkdir -p "${path_build_openssl}"
       mkdir -p "${path_build_openssl_arch}"
       rm -rf -- "${path_build_openssl_arch}"
       mkdir -p "${path_build_openssl_arch}"

       log_build_openssl="${path_build_openssl_arch}/build-openssl-${version_openssl}.log"

       > "$log_build_openssl"


       printf "Building OpenSSL.\n"

       set +e
       if [[ "$version_openssl" =~ 1.0.0. ]]; then
          ./Configure BSD-generic32 --openssldir="${path_build_openssl_arch}" > "${log_build_openssl}" 2>&1
       elif [ "${arch}" == "x86_64" ]; then
          ./Configure darwin64-x86_64-cc --openssldir="${path_build_openssl_arch}" > "${log_build_openssl}" 2>&1
       else
          ./Configure iphoneos-cross --openssldir="${path_build_openssl_arch}" > "${log_build_openssl}" 2>&1
       fi
     
       if [ $? != 0 ];
       then 
          echo "Problem while configure - Please check ${log_build_openssl}"
          exit 1
       fi

       # add -isysroot to CC=
       sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${version_ios_min} !" "Makefile"

       make >> "${log_build_openssl}" 2>&1

       if [ $? != 0 ];
       then 
          echo "Problem while make - Please check ${log_build_openssl}"
          exit 1
       fi
     
       set -e
       make install >> "${log_build_openssl}" 2>&1
       make clean >> "${log_build_openssl}" 2>&1

    done

    rm -rf "${path_library_openssl}"
    mkdir -p "${path_library_openssl}"

    command_lipo_libcrypto="${command_lipo_libcrypto} -output ${path_library_openssl}/libcrypto.a"
    $command_lipo_libcrypto

    command_lipo_libssl="${command_lipo_libssl} -output ${path_library_openssl}/libssl.a"
    $command_lipo_libssl

    path_build_openssl_arch_include=${path_build_openssl_arch}/include
    path_library_openssl_include=${path_library_openssl}
    mkdir -p ${path_library_openssl_include}

    cp -R $path_build_openssl_arch_include $path_library_openssl

    path_library_openssl="${path_library_openssl}/include"

    sed -ie "s/# include <openssl\/opensslconf.h>/# include \"opensslconf.h\"/g" "${path_library_openssl}/openssl/evp.h"
    sed -ie "s/#include <openssl\/ossl_typ.h>/#include \"ossl_typ.h\"/g" "${path_library_openssl}/openssl/evp.h"
    sed -ie "s/#include <openssl\/symhacks.h>/#include \"symhacks.h\"/g" "${path_library_openssl}/openssl/evp.h"
    sed -ie "s/#include <openssl\/bio.h>/#include \"bio.h\"/g" "${path_library_openssl}/openssl/evp.h"

    sed -ie "s/#include <openssl\/objects.h>/#include \"objects.h\"/g" "${path_library_openssl}/openssl/evp.h"

    sed -ie "s/#include <openssl\/e_os2.h>/#include \"e_os2.h\"/g" "${path_library_openssl}/openssl/bn.h"

    sed -ie "s/#include <openssl\/ossl_typ.h>/#include \"ossl_typ.h\"/g" "${path_library_openssl}/openssl/bn.h"
    sed -ie "s/#include <openssl\/crypto.h>/#include \"crypto.h\"/g" "${path_library_openssl}/openssl/bn.h"

    sed -ie "s/#include <openssl\/asn1.h>/#include \"asn1.h\"/g" "${path_library_openssl}/openssl/pkcs7.h"

    sed -ie "s/#include <openssl\/bio.h>/#include \"bio.h\"/g" "${path_library_openssl}/openssl/pkcs7.h"
    sed -ie "s/#include <openssl\/e_os2.h>/#include \"e_os2.h\"/g" "${path_library_openssl}/openssl/pkcs7.h"
    sed -ie "s/#include <openssl\/symhacks.h>/#include \"symhacks.h\"/g" "${path_library_openssl}/openssl/pkcs7.h"
    sed -ie "s/#include <openssl\/ossl_typ.h>/#include \"ossl_typ.h\"/g" "${path_library_openssl}/openssl/pkcs7.h"

    sed -ie "s/#include <openssl\/e_os2.h>/#include \"e_os2.h\"/g" "${path_library_openssl}/openssl/asn1.h"
    sed -ie "s/#include <openssl\/bio.h>/#include \"bio.h\"/g" "${path_library_openssl}/openssl/asn1.h"

    sed -ie "s/#include <openssl\/stack.h>/#include \"stack.h\"/g" "${path_library_openssl}/openssl/asn1.h"
    sed -ie "s/#include <openssl\/safestack.h>/#include \"safestack.h\"/g" "${path_library_openssl}/openssl/asn1.h"
    sed -ie "s/#include <openssl\/symhacks.h>/#include \"symhacks.h\"/g" "${path_library_openssl}/openssl/asn1.h"
    sed -ie "s/#include <openssl\/ossl_typ.h>/#include \"ossl_typ.h\"/g" "${path_library_openssl}/openssl/asn1.h"

    sed -ie "s/#include <openssl\/bn.h>/#include \"bn.h\"/g" "${path_library_openssl}/openssl/asn1.h"

    sed -ie "s/#include <openssl\/opensslconf.h>/#include \"opensslconf.h\"/g" "${path_library_openssl}/openssl/e_os2.h"

    sed -ie "s/#include <openssl\/e_os2.h>/#include \"e_os2.h\"/g" "${path_library_openssl}/openssl/bio.h"
    sed -ie "s/#include <openssl\/crypto.h>/#include \"crypto.h\"/g" "${path_library_openssl}/openssl/bio.h"

    sed -ie "s/#include <openssl\/e_os2.h>/#include \"e_os2.h\"/g" "${path_library_openssl}/openssl/crypto.h"
    sed -ie "s/#include <openssl\/stack.h>/#include \"stack.h\"/g" "${path_library_openssl}/openssl/crypto.h"
    sed -ie "s/#include <openssl\/symhacks.h>/#include \"symhacks.h\"/g" "${path_library_openssl}/openssl/crypto.h"

    sed -ie "s/#include <openssl\/safestack.h>/#include \"safestack.h\"/g" "${path_library_openssl}/openssl/crypto.h"
    sed -ie "s/#include <openssl\/opensslv.h>/#include \"opensslv.h\"/g" "${path_library_openssl}/openssl/crypto.h"
    sed -ie "s/#include <openssl\/ossl_typ.h>/#include \"ossl_typ.h\"/g" "${path_library_openssl}/openssl/crypto.h"

    sed -ie "s/#include <openssl\/e_os2.h>/#include \"e_os2.h\"/g" "${path_library_openssl}/openssl/ossl_typ.h"

    sed -ie "s/#include <openssl\/stack.h>/#include \"stack.h\"/g" "${path_library_openssl}/openssl/safestack.h"
    sed -ie "s/#include <openssl\/e_os2.h>/#include \"e_os2.h\"/g" "${path_library_openssl}/openssl/symhacks.h"

    sed -ie "s/#include <openssl\/obj_mac.h>/#include \"obj_mac.h\"/g" "${path_library_openssl}/openssl/objects.h"
    sed -ie "s/#include <openssl\/bio.h>/#include \"bio.h\"/g" "${path_library_openssl}/openssl/objects.h"
    sed -ie "s/#include <openssl\/asn1.h>/#include \"asn1.h\"/g" "${path_library_openssl}/openssl/objects.h"

    sed -ie "s/#include <openssl\/e_os2.h>/#include \"e_os2.h\"/g" "${path_library_openssl}/openssl/sha.h"

    sed -ie "s/#include <openssl\/e_os2.h>/#include \"e_os2.h\"/g" "${path_library_openssl}/openssl/x509.h"
    sed -ie "s/#include <openssl\/symhacks.h>/#include \"symhacks.h\"/g" "${path_library_openssl}/openssl/x509.h"
    sed -ie "s/#include <openssl\/buffer.h>/#include \"buffer.h\"/g" "${path_library_openssl}/openssl/x509.h"
    sed -ie "s/#include <openssl\/evp.h>/#include \"evp.h\"/g" "${path_library_openssl}/openssl/x509.h"
    sed -ie "s/#include <openssl\/bio.h>/#include \"bio.h\"/g" "${path_library_openssl}/openssl/x509.h"
    sed -ie "s/#include <openssl\/stack.h>/#include \"stack.h\"/g" "${path_library_openssl}/openssl/x509.h"
    sed -ie "s/#include <openssl\/asn1.h>/#include \"asn1.h\"/g" "${path_library_openssl}/openssl/x509.h"
    sed -ie "s/#include <openssl\/safestack.h>/#include \"safestack.h\"/g" "${path_library_openssl}/openssl/x509.h"

    sed -ie "s/#include <openssl\/ec.h>/#include \"ec.h\"/g" "${path_library_openssl}/openssl/x509.h"

    sed -ie "s/#include <openssl\/ecdsa.h>/#include \"ecdsa.h\"/g" "${path_library_openssl}/openssl/x509.h"
    sed -ie "s/#include <openssl\/ecdh.h>/#include \"ecdh.h\"/g" "${path_library_openssl}/openssl/x509.h"

    sed -ie "s/#include <openssl\/rsa.h>/#include \"rsa.h\"/g" "${path_library_openssl}/openssl/x509.h"
    sed -ie "s/#include <openssl\/dsa.h>/#include \"dsa.h\"/g" "${path_library_openssl}/openssl/x509.h"

    sed -ie "s/#include <openssl\/dh.h>/#include \"dh.h\"/g" "${path_library_openssl}/openssl/x509.h"

    sed -ie "s/#include <openssl\/sha.h>/#include \"sha.h\"/g" "${path_library_openssl}/openssl/x509.h"
    sed -ie "s/#include <openssl\/ossl_typ.h>/#include \"ossl_typ.h\"/g" "${path_library_openssl}/openssl/x509.h"

    sed -ie "s/#include <openssl\/x509_vfy.h>/#include \"x509_vfy.h\"/g" "${path_library_openssl}/openssl/x509.h"
    sed -ie "s/#include <openssl\/pkcs7.h>/#include \"pkcs7.h\"/g" "${path_library_openssl}/openssl/x509.h"

    sed -ie "s/#include <openssl\/opensslconf.h>/#include \"opensslconf.h\"/g" "${path_library_openssl}/openssl/x509_vfy.h"
    sed -ie "s/#include <openssl\/lhash.h>/#include \"lhash.h\"/g" "${path_library_openssl}/openssl/x509_vfy.h"
    sed -ie "s/#include <openssl\/bio.h>/#include \"bio.h\"/g" "${path_library_openssl}/openssl/x509_vfy.h"
    sed -ie "s/#include <openssl\/crypto.h>/#include \"crypto.h\"/g" "${path_library_openssl}/openssl/x509_vfy.h"

    sed -ie "s/#include <openssl\/symhacks.h>/#include \"symhacks.h\"/g" "${path_library_openssl}/openssl/x509_vfy.h"

    sed -ie "s/#include <openssl\/opensslconf.h>/#include \"opensslconf.h\"/g" "${path_library_openssl}/openssl/ec.h"
    sed -ie "s/#include <openssl\/asn1.h>/#include \"asn1.h\"/g" "${path_library_openssl}/openssl/ec.h"
    sed -ie "s/#include <openssl\/symhacks.h>/#include \"symhacks.h\"/g" "${path_library_openssl}/openssl/ec.h"
    sed -ie "s/#include <openssl\/bn.h>/#include \"bn.h\"/g" "${path_library_openssl}/openssl/ec.h"

    sed -ie "s/#include <openssl\/opensslconf.h>/#include \"opensslconf.h\"/g" "${path_library_openssl}/openssl/ecdsa.h"
    sed -ie "s/#include <openssl\/ec.h>/#include \"ec.h\"/g" "${path_library_openssl}/openssl/ecdsa.h"
    sed -ie "s/#include <openssl\/ossl_typ.h>/#include \"ossl_typ.h\"/g" "${path_library_openssl}/openssl/ecdsa.h"

    sed -ie "s/#include <openssl\/bn.h>/#include \"bn.h\"/g" "${path_library_openssl}/openssl/ecdsa.h"

    sed -ie "s/#include <openssl\/opensslconf.h>/#include \"opensslconf.h\"/g" "${path_library_openssl}/openssl/ecdh.h"
    sed -ie "s/#include <openssl\/ec.h>/#include \"ec.h\"/g" "${path_library_openssl}/openssl/ecdh.h"
    sed -ie "s/#include <openssl\/ossl_typ.h>/#include \"ossl_typ.h\"/g" "${path_library_openssl}/openssl/ecdh.h"
    sed -ie "s/#include <openssl\/bn.h>/#include \"bn.h\"/g" "${path_library_openssl}/openssl/ecdh.h"

    sed -ie "s/#include <openssl\/ossl_typ.h>/#include \"ossl_typ.h\"/g" "${path_library_openssl}/openssl/buffer.h"

    sed -ie "s/#include <openssl\/asn1.h>/#include \"asn1.h\"/g" "${path_library_openssl}/openssl/rsa.h"
    sed -ie "s/#include <openssl\/bio.h>/#include \"bio.h\"/g" "${path_library_openssl}/openssl/rsa.h"
    sed -ie "s/#include <openssl\/crypto.h>/#include \"crypto.h\"/g" "${path_library_openssl}/openssl/rsa.h"
    sed -ie "s/#include <openssl\/ossl_typ.h>/#include \"ossl_typ.h\"/g" "${path_library_openssl}/openssl/rsa.h"
    sed -ie "s/#include <openssl\/bn.h>/#include \"bn.h\"/g" "${path_library_openssl}/openssl/rsa.h"

    sed -ie "s/#include <openssl\/bn.h>/#include \"bn.h\"/g" "${path_library_openssl}/openssl/dsa.h"
    sed -ie "s/#include <openssl\/e_os2.h>/#include \"e_os2.h\"/g" "${path_library_openssl}/openssl/dsa.h"
    sed -ie "s/#include <openssl\/bio.h>/#include \"bio.h\"/g" "${path_library_openssl}/openssl/bio.h"
    sed -ie "s/#include <openssl\/crypto.h>/#include \"crypto.h\"/g" "${path_library_openssl}/openssl/dsa.h"
    sed -ie "s/#include <openssl\/ossl_typ.h>/#include \"ossl_typ.h\"/g" "${path_library_openssl}/openssl/dsa.h"
    sed -ie "s/# include <openssl\/dh.h>/# include \"dh.h\"/g" "${path_library_openssl}/openssl/dsa.h"
    sed -ie "s/#include <openssl\/bio.h>/#include \"bio.h\"/g" "${path_library_openssl}/openssl/dsa.h"

    sed -ie "s/#include <openssl\/ossl_typ.h>/#include \"ossl_typ.h\"/g" "${path_library_openssl}/openssl/dh.h"
    sed -ie "s/#include <openssl\/e_os2.h>/#include \"e_os2.h\"/g" "${path_library_openssl}/openssl/dh.h"
    sed -ie "s/#include <openssl\/bio.h>/#include \"bio.h\"/g" "${path_library_openssl}/openssl/dh.h"
    sed -ie "s/#include <openssl\/bn.h>/#include \"bn.h\"/g" "${path_library_openssl}/openssl/dh.h"

    sed -ie "s/#include <openssl\/e_os2.h>/#include \"e_os2.h\"/g" "${path_library_openssl}/openssl/lhash.h"
    sed -ie "s/#include <openssl\/bio.h>/#include \"bio.h\"/g" "${path_library_openssl}/openssl/lhash.h"

    sed -ie "s/#include <openssl\/e_os2.h>/#include \"e_os2.h\"/g" "${path_library_openssl}/openssl/err.h"
    sed -ie "s/#include <openssl\/ossl_typ.h>/#include \"ossl_typ.h\"/g" "${path_library_openssl}/openssl/err.h"
    sed -ie "s/#include <openssl\/bio.h>/#include \"bio.h\"/g" "${path_library_openssl}/openssl/err.h"
    sed -ie "s/#include <openssl\/lhash.h>/#include \"lhash.h\"/g" "${path_library_openssl}/openssl/err.h"

fi

#
# MySQL Connector - Comp_err OS X swizzle - Correct way to do it.
#

mysql_custom_openssl=$true

if [[ $build_mysql_ios7 == $true  && $show_help == $false ]]; then

    echo "Building libmysqlclient"

   # Build for native platform, so we can get the comp_err program.
   #  The comp_error must run for error messages to be generated for
   #  the libs, but since the libs are armv, we need to do a native
   #  generation of this helper application.

   command_lipo_mysql="${command_lipo_create}"
   path_library_mysql="${path_library}/libmysqlclient"

   path_source_mysql_native="${path_source}/native"

   mkdir -p "${path_source_mysql_native}"
   rm -rf -- "${path_source_mysql_native}"
   mkdir -p "${path_source_mysql_native}"
   tar zxf ${path_media_mysql} -C ${path_source_mysql_native}

   pushd ${path_source_mysql_native}/${archive_name_mysql}
   mkdir -p "${path_build_mysql}"
   rm -rf -- "${path_build_mysql}"
   mkdir -p "${path_build_mysql}"
   log_build_mysql="${path_build_mysql}/build-mysql-native-release.log"

   cmake -Wno-dev -GXcode >> $log_build_mysql &
   spinner $!

   #sed -ie 's/compile_time_assert(sizeof(LF_PINS) == 64);/\/\/compile_time_assert(sizeof(LF_PINS) == 64);/g' 'mysys/lf_alloc-pin.c'

   xcodebuild -project LibMySQL.xcodeproj -target mysqlclient -configuration Release -sdk macosx${version_macosx}  >> $log_build_mysql &
   spinner $!


   popd

    for platform in $platform_iphoneos $platform_simulator
    do

        if [ "${platform}" == "${platform_iphoneos}" ]
        then
            sdk_build=${sdk_iphoneos}
            archs_to_build=$archs_ios
        else
            sdk_build=${sdk_simulator}
            archs_to_build=$archs_macosx
        fi


        platform_version_arch="${platform}${version_ios}"
        path_build_mysql_arch="${path_build_mysql}/$platform_version_arch.sdk"

        mkdir -p "${path_build_mysql_arch}"
        log_build_mysql="${path_build_mysql}/build-mysql-${version_mysql}-${platform}.log"
        > "$log_build_mysql"

        cd "${path_base}"

        printf "\n%s\n" "$formatting_divider"
        printf "Extracting MySQL source code.\n"
        rm -rf -- "${path_source_mysql}"
        mkdir -p "${path_source_mysql}"
        tar zxf ${path_media_mysql} -C ${path_source}

        printf "CD %s\n" "${path_source_mysql}"
        cd "${path_source_mysql}"

        archs_cmake=$(echo $archs | sed -e "s/ /\\;/g")

        if [ $mysql_custom_openssl == $true ]
        then
            cmake -DWITH_SSL=$path_library_openssl -Wno-dev -GXcode # >> $log_build_mysql &
            spinner $!
        else
            cmake -Wno-dev -GXcode >> $log_build_mysql &
            spinner $!
        fi


        sed -ie "s/"'CMAKE_INTDIR=\\\"\$(CONFIGURATION)\$(EFFECTIVE_PLATFORM_NAME)\\\"'\"/"'CMAKE_INTDIR=\\\"\$(CONFIGURATION)\\\"'\"/g" "LibMySQL.xcodeproj/project.pbxproj"
        sed -ie "s/\"-Wl,-search_paths_first\",//g" "LibMySQL.xcodeproj/project.pbxproj"
        sed -ie "s/\"-Wl,-headerpad_max_install_names\",//g" "LibMySQL.xcodeproj/project.pbxproj"
        sed -ie "s/\"-dynamiclib\",//g" "LibMySQL.xcodeproj/project.pbxproj"
        sed -ie "s/com.apple.product-type.library.dynamic/com.apple.product-type.library.static/g" "LibMySQL.xcodeproj/project.pbxproj"
        sed -ie "s/com.apple.product-type.tool/com.apple.product-type.library.static/g" "LibMySQL.xcodeproj/project.pbxproj"
        sed -ie 's/compile_time_assert(sizeof(LF_PINS) == 64);/\/\/compile_time_assert(sizeof(LF_PINS) == 64);/g' 'mysys/lf_alloc-pin.c'
        sed -ie 's/\/* #undef WORDS_BIGENDIAN *\\/define WORDS_BIGENDIAN 1/g' 'include/my_config.h'
        sed -ie 's/-Wl,-search_paths_first//g' 'LibMySQL.xcodeproj/project.pbxproj'
        sed -ie 's/-Wl,-headerpad_max_install_names//g' 'LibMySQL.xcodeproj/project.pbxproj'

        product_name_mysql="mysqlclient"

        if xcodebuild -project LibMySQL.xcodeproj -target mysqlclient -configuration Release -sdk ${sdk_build} ONLY_ACTIVE_ARCH=NO ARCHS="${archs_to_build}" VALID_ARCHS="${archs_valid}" >> $log_build_mysql
        then
            echo "Fuck, is unexpected success really success?"
            exit 6
        else
            echo "First build failed as expected."
            cp -r mysys/Release-$platform mysys/Release
            cp -r mysys/Release-$platform mysys/Release
            cp -r mysys_ssl/Release-$platform mysys_ssl/Release
            cp -r dbug/Release-$platform dbug/Release
            cp -r strings/Release-$platform strings/Release
            cp -r zlib/Release-$platform zlib/Release
            if [ $mysql_custom_openssl != $true ]
            then
                cp -r extra/yassl/Release-$platform extra/yassl/Release
                cp -r extra/yassl/taocrypt/Release-$platform extra/yassl/taocrypt/Release
            fi
            cp -r ../native/${archive_name_mysql}/extra/Release extra/Release

            if xcodebuild -project LibMySQL.xcodeproj  -target mysqlclient -configuration Release -sdk ${sdk_build} ONLY_ACTIVE_ARCH=NO ARCHS="${archs_to_build}" VALID_ARCHS="${archs_valid}" >> $log_build_mysql
            then
                echo "All Good"
                build_result="${path_source_mysql}/libmysql/Release-${platform}/lib${product_name_mysql}.a"
                if [ -e "$build_result" ]
                then
                    path_to_libmysql="${path_build_mysql_arch}/lib${product_name_mysql}.a"
                    command_lipo_mysql="${command_lipo_mysql} ${path_to_libmysql}"
                    cp "${build_result}" "${path_to_libmysql}"
                else
                    echo "Can't find build result: %s" "${build_result}"
                    exit 4
                fi

            else
                echo "Build two failed.  This one should work."
                exit 5
            fi
        fi
    done

    printf "%s\n" "${path_library_mysql}"

    mkdir -p "${path_library_mysql}"

    printf "%s\n" "${path_source_mysql}/include\" \"${path_library_mysql}"

    cp -R "${path_source_mysql}/include" "${path_library_mysql}"

    sed -ie 's/#include <mysql\/plugin_auth_common.h>/#include "plugin_auth_common.h"/g' '${path_source_mysql}/include/mysql/client_plugin.h'
    sed -ie 's/#include <mysql/psi/psi_memory.h>/#include "mysql/psi/psi_memory.h"/g' '${path_source_mysql}/include/mysql/psi/psi_memory.h'

    path_library_mysql="${path_library_mysql}/libmysqlclient.a"
    command_lipo_mysql="${command_lipo_mysql} -output ${path_library_mysql}"

    $command_lipo_mysql

fi

#
# MySQL Connector - OS X Hack - Do not use.
#

if [[ $build_mysql == $true  && $show_help == $false ]]; then

   command_lipo_mysql="${command_lipo_create}"
   path_library_mysql="${path_library}/libmysqlclient"

   mkdir -p "${path_build_mysql}"
   for arch in ${archs}
   do

       if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
       then
          platform="iphonesimulator"
          sdk_build=${sdk_simulator}
       else
          platform="iphoneos"
          sdk_build=${sdk_iphoneos}
       fi

       platform_version_arch="${platform}${version_ios}-${arch}"
       path_build_mysql_arch="${path_build_mysql}/$platform_version_arch.sdk"

       mkdir -p "${path_build_mysql_arch}"
       log_build_mysql="${path_build_mysql}/build-mysql-${version_mysql}-${arch}.log"
       > "$log_build_mysql"

       cd "${path_base}"

       printf "\n%s\n" "$formatting_divider"
       printf "Extracting MySQL source code.\n"
       rm -rf -- "${path_source_mysql}"
       mkdir -p "${path_source_mysql}"
       tar zxf ${path_media_mysql} -C ${path_source}

       cd "${path_source_mysql}"

       archs_cmake=$(echo $archs | sed -e "s/ /\\;/g")

       sysroot="${path_xcode}/Platforms/${platform}.platform/Developer/SDKs/iPhoneOS${version_ios}.sdk"

       printf "Configuring MySQL\n"

       cmake -GXcode >> $log_build_mysql &
       spinner $!

       if [ "$version_mysql" == "$version_mysql_6_0" ]
       then
          sed -ie 's/#include <netinet\/in_systm.h>/\/\/#include <netinet\/in_systm.h>/' 'include/my_net.h'
          sed -ie 's/#include <netinet\/ip.h>/\/\/#include <netinet\/ip.h>/' 'include/my_net.h'
          sed -ie 's/#  if defined(__i386__) || defined(__ppc__)/#if defined(__i386__) || defined(__ppc__) || defined(__arm__)/' 'include/my_global.h'
          sed -ie 's/#define HAVE_FDATASYNC/\/\/#define HAVE_FDATASYNC/' 'include/my_config.h'
          sed -ie 's/#define THREAD 1/\/\/#define THREAD 1/' 'include/my_config.h'
          sed -ie 's/pthread_yield();/\/\/pthread_yield();/' 'mysys/lf_alloc-pin.c'
          sed -ie 's/safe_mutex_assert_owner(&keycache->cache_lock);/\/\/safe_mutex_assert_owner(&keycache->cache_lock);/' 'mysys/mf_keycache.c'
          sed -ie 's/pthread_mutex_init(\&rc->lock.mutex, MY_MUTEX_INIT_FAST);/\/\/pthread_mutex_init(\&rc->lock.mutex, MY_MUTEX_INIT_FAST);/' 'mysys/waiting_threads.c'
          sed -ie 's/set_timespec_time_nsec/\/\/set_timespec_time_nsec/g' 'mysys/waiting_threads.c'
          sed -ie '1784i\
#ifdef THREAD' 'mysys/mf_keycache.c'
          sed -ie '1814i\
#endif
' 'mysys/mf_keycache.c'
          sed -ie 's/el->stack_ends_here= & my_thread_var->stack_ends_here;/\/\/el->stack_ends_here= & my_thread_var->stack_ends_here;/g' 'mysys/lf_alloc-pin.c'
       fi

       if [ "$version_mysql" == "$version_mysql_6_1" ]
       then
          printf "Fixing MySQL source to work for iOS.\n"
       fi

      product_name_mysql="mysqlclient_device"

      print_building "MySQL" $version_mysql $arch

      xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk "${sdk_build}" ONLY_ACTIVE_ARCH=NO ARCHS="$arch" VALID_ARCHS="${archs_valid}" PRODUCT_NAME=${product_name_mysql} >> $log_build_mysql &
      spinner $!

      path_to_libmysql="${path_build_mysql_arch}/lib${product_name_mysql}.a"
      build_result="${path_source_mysql}/libmysql/Release-${platform}/lib${product_name_mysql}.a"
      if [ -e "$build_result" ]
      then
         command_lipo_mysql="${command_lipo_mysql} ${path_to_libmysql}"
         cp "${build_result}" "${path_to_libmysql}"
      else
         printf "Build failed.\n"
      fi

    done

    mkdir -p "${path_library_mysql}"
    cp -R "${path_source_mysql}/include" "${path_library_mysql}"

    path_library_mysql="${path_library_mysql}/libmysqlclient.a"
    command_lipo_mysql="${command_lipo_mysql} -output ${path_library_mysql}"

    $command_lipo_mysql

fi

#
# PNG
#

if [[ $build_png == $true  && $show_help == $false ]]; then

   command_lipo_png="${command_lipo_create}"
   path_library_png="${path_library}/libpng"

   for arch in ${archs}
   do
      if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
      then
         platform="iPhoneSimulator"
         additional_config="--enable-arm-neon=no "
      else
         platform="iPhoneOS"

         additional_config="--enable-arm-neon=no "
         if [[ "${architecture}" == "armv7" ]];
         then
            additional_config="--enable-arm-neon=no "
         elif [[ "${architecture}" == "arm64" ]];
         then
            additional_config="--enable-arm-neon=yes "
         else
            additional_config="--enable-arm-neon=yes "
         fi
      fi

      platform_version_arch="${platform}${version_ios}-${arch}"
      path_build_png_arch="${path_build_png}/$platform_version_arch.sdk"

      mkdir -p "${path_build_png_arch}"
      rm -rf -- "${path_build_png_arch}"
      log_build_png="${path_build_png}/build-libpng-${version_png}-${arch}.log"
      > "$log_build_png"

      cd "${path_base}"

      extract_source $path_media_png $path_source &
      spinner $!

      cd "${path_source_png}"

      command_lipo_png="${command_lipo_png} ${path_build_png_arch}/lib/libpng.a"

      config_make_install $version_ios $version_ios_min $arch $additional_config $path_build_png_arch $log_build_png # $1=sdk-version $2=sdk-min-version $3=arch $4=additionalConfig $5=make-path $6=log-path

   done

   mkdir -p "${path_library_png}"
   rm -rf -- "${path_library_png}"
   mkdir -p "${path_library_png}"

   cp -R "${path_build_png_arch}/include" "${path_library_png}"
   command_lipo_png="${command_lipo_png} -output ${path_library_png}/libpng16.a"
   ln -s "${path_library_png}/libpng16.a" "${path_library_png}/libpng.a"
   $command_lipo_png

fi

#
# TDS
#

if [[ $build_tds == $true  && $show_help == $false ]]; then

   set -e

   command_lipo_tds="${command_lipo_create}"
   command_lipo_ct="${command_lipo_create}"
   path_library_tds="${path_library}/libsybdb"

   for arch in ${archs}
   do
      platform=$( platform_for_architecture arch )

      printf "\n\nBuilding Freetds for %s %s." "${arch}" "${platform}"

      platform_version_arch="${platform}${version_ios}-${arch}"
      path_build_tds_arch="${path_build_tds}/$platform_version_arch.sdk"

#printf "mkdir %s\n" "${path_build_tds_arch}"

      mkdir -p "${path_build_tds_arch}"
      rm -rf -- "${path_build_tds_arch}"
      mkdir -p "${path_build_tds_arch}"
      log_build_tds="${path_build_tds}/build-tds-${version_freetds}-${arch}.log"
      > "$log_build_tds"

      cd "${path_base}"

      extract_source $path_media_tds $path_source &
      spinner $!

      cd "${path_source_tds}"

      command_lipo_tds="${command_lipo_tds} ${path_build_tds_arch}/lib/libsybdb.a"
      command_lipo_ct="${command_lipo_ct} ${path_build_tds_arch}/lib/libct.a"
      additional_config=" -with-tdsver=${version_tds} "
        additional_work="addtional_work_libsybdb"

      config_make_install $version_ios $version_ios_min $arch $additional_config $path_build_tds_arch $log_build_tds $additional_work

   done

   printf "mkdir %s\n" "${path_library_tds}"

   mkdir -p "${path_library_tds}"
   rm -rf -- "${path_library_tds}"
   mkdir -p "${path_library_tds}"

   printf "cp -R %s\n" "${path_build_tds_arch}/include\" \"${path_library_tds}"

   cp -R $path_build_tds_arch/include $path_library_tds

   command_lipo_tds="${command_lipo_tds} -output ${path_library_tds}/libsybdb.a"
   command_lipo_ct="${command_lipo_ct} -output ${path_library_tds}/libct.a"

   echo ""
   echo "${command_lipo_tds}"
   echo ""
   echo "${command_lipo_ct}"
   echo ""

   $command_lipo_tds
   $command_lipo_ct

fi

#
# ZINT
#
# Unfinished... Included in code.
#

if [[ $build_zint == $true  && $show_help == $false ]]; then

   command_lipo_zint="${command_lipo_create}"

   platform=$( platform_for_architecture arch )

   printf "Extracting Zint source code.\n"
   rm -rf -- "${path_source_zint}"
   mkdir -p "${path_source_zint}"
   tar zxf ${path_media_zint} -C ${path_source}

   platform_version_arch="${platform}${version_ios}-${arch}"
   path_build_zint_arch="${path_build_zint}/$platform_version_arch.sdk"

   mkdir -p "${path_build_zint_arch}"
   rm -rf -- "${path_build_zint_arch}"
   mkdir -p "${path_build_zint_arch}"
   log_build_zint="${path_build_zint}/build-zint-${version_zint}-${arch}.log"
   > "$log_build_zint"

   cd "${path_base}"

   extract_source $path_media_zint $path_source &
   spinner $!

   cd "${path_source_zint}"

   command_lipo_zint="${command_lipo_zint} ${path_build_zint_arch}/libzint.a"
   additional_config=""

   config_make_install $version_ios $version_ios_min $arch $additional_config $path_build_zint_arch $log_build_zint # $1=sdk-version $2=sdk-min-version $3=arch $4=additionalConfig $5=make-path $6=log-path

fi

#
# Attr - Required by Glib
#   Unused way to (maybe) cross compile gettext.  Why?  Becuse, fuck it.
#

build_attr_static_ios() {

    readonly archive_attr_base_url="http://download.savannah.gnu.org/releases/attr/"
    readonly archive_name_attr="attr-${version_attr}"
    readonly archive_attr="${archive_name_attr}.src.tar.gz"
    readonly path_source_attr="$path_source/$archive_name_attr"
    readonly path_media_attr="$path_media/$archive_attr"
    readonly path_build_attr="${path_build}/attr"

    download_archive $archive_attr $archive_attr_base_url

    echo "Building attr."

    command_lipo_attr="${command_lipo_create}"

    for arch in ${archs}
    do

        platform=$( platform_for_architecture arch )

        platform_version_arch="${platform}${version_ios}-${arch}"
        path_build_attr_arch="${path_build_attr}/$platform_version_arch.sdk"

        mkdir -p "${path_build_attr_arch}"
        rm -rf -- "${path_build_attr_arch}"
        mkdir -p "${path_build_attr_arch}"
        tar zxf ${path_media_attr} -C ${path_build_attr_arch}

        log_build_attr="${path_build_attr_arch}/build-attr-${version_attr}-${arch}.log"
        > "$log_build_attr"

        prepp="${path_build_attr}/$platform_version_arch.sdk/${archive_name_attr}"
        cd "${prepp}"

        extract_source $path_media_attr $path_build_attr_arch &
        spinner $!

        cd "${prepp}"

        additional_config="--enable-gui=no "

        printf "Build path %s.\n" "$path_build_attr_arch"
        printf "Build conf %s.\n" "$additional_config"
        printf "Build arch %s.\n" "$arch"
        printf "Build log  %s.\n" "$log_build_attr"

#export CFLAGS=" -I${path_library}/crt_externs "
#export CPPFLAGS=" -I${path_library}/crt_externs "

        config_make_install $version_ios $version_ios_min $arch $additional_config $prepp $log_build_attr
exit 0
    done
}

path_library_attr="${path_library}/attr"

if [[ $build_attr == $true && $show_help == $false ]]; then

    build_attr_static_ios
fi

#
# Acl - Required by Glib
#   Unused way to (maybe) cross compile acl.  Why?  Becuse, fuck it.
#

build_acl_static_ios() {

    build_attr_static_ios

    readonly archive_acl_base_url="http://download.savannah.gnu.org/releases/acl/"
    readonly archive_name_acl="acl-${version_acl}"
    readonly archive_acl="${archive_name_acl}.src.tar.gz"
    readonly path_source_acl="$path_source/$archive_name_acl"
    readonly path_media_acl="$path_media/$archive_acl"
    readonly path_build_acl="${path_build}/acl"

    download_archive $archive_acl $archive_acl_base_url

    echo "Building acl."

    command_lipo_acl="${command_lipo_create}"

    for arch in ${archs}
    do

        platform=$( platform_for_architecture arch )

        platform_version_arch="${platform}${version_ios}-${arch}"
        path_build_acl_arch="${path_build_acl}/$platform_version_arch.sdk"

        mkdir -p "${path_build_acl_arch}"
        rm -rf -- "${path_build_acl_arch}"
        mkdir -p "${path_build_acl_arch}"
        tar zxf ${path_media_acl} -C ${path_build_acl_arch}

        log_build_acl="${path_build_acl_arch}/build-acl-${version_acl}-${arch}.log"
        > "$log_build_acl"

        prepp="${path_build_acl}/$platform_version_arch.sdk/${archive_name_acl}"
        cd "${prepp}"

        extract_source $path_media_acl $path_build_acl_arch &
        spinner $!

        cd "${prepp}"

        additional_config="--enable-gui=no "

        printf "Build path %s.\n" "$path_build_acl_arch"
        printf "Build conf %s.\n" "$additional_config"
        printf "Build arch %s.\n" "$arch"
        printf "Build log  %s.\n" "$log_build_acl"

        export CFLAGS=" -I${path_library}/crt_externs "
        export CPPFLAGS=" -I${path_library}/crt_externs "

        config_make_install $version_ios $version_ios_min $arch $additional_config $prepp $log_build_acl
exit 0
    done
}

path_library_acl="${path_library}/acl"

if [[ $build_acl == $true && $show_help == $false ]]; then

    build_acl_static_ios
fi

empty_directory $path_build
empty_directory $path_source

printf "Compressor is done.\n"
