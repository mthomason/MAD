#!/bin/sh

#  buildcounter.sh
#  MAD
#
#  Created by Michael Thomason on 1/24/14.
#  Copyright © 2017 Michael Thomason. All rights reserved.

# This is a bit of a mess.  It might work, or you might start building Unix from scratch.  Probably
#	use some judgement, and read it, before you start to use this script.

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
	printf "  %s\n" "--gettext                Build Gettext.\n"
	printf "  %s\n" "--acl                    Build Gettext.\n"
	printf "  %s\n" "--libarchive             Build Archive.\n"
	printf "  %s\n" "--openssl                Build OpenSSL.\n"
	printf "  %s\n" "--freetds                Build FreeTds.\n"
	printf "  %s\n" "--libpng                 Build libpng.\n"
	printf "  %s\n" "--mysql                  Build MySQL Connector.\n"
	printf "  %s\n" "-h,--help                Show help.\n"
}

build_openssl=$false
build_png=$false
build_mysql=$false
build_mysql_ios7=$false
build_tds=$false
build_zint=$false
build_unixodbc=$false
build_libarchive=$false
build_libbzip=$false
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

		--libbzip)
			build_libbzip=$true;;

		--libarchive)
			build_libarchive=$true;;

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

# Globals
readonly version_openssl="1.0.2r"
readonly version_mysql="6.1.11"
readonly version_freetds="1.1.5"
readonly version_tds=7.1
readonly version_zint="2.4.2"
readonly version_png="1.6.37"
readonly version_unixodbc="2.3.2"
readonly version_autoconf="2.69"
readonly version_automake="1.14"
readonly version_gettext="0.18.3.1"
readonly version_acl="2.2.52"
readonly version_attr="2.4.47"
readonly version_libarchive="3.3.3"
readonly version_bzip="1.0.6"

readonly version_mysql_6_0="6.0.2"  #do not change
readonly version_mysql_6_1="6.1.11"

readonly platform_iphoneos="iphoneos"
readonly platform_simulator="iphonesimulator"
readonly platform_macosx="macosx"

readonly platforms="${platform_iphoneos} ${platform_simulator} ${platform_macosx}"

readonly path_xcode=$( xcode-select -print-path )

readonly version_macosx=$( version_for_platform $platform_macosx )
readonly version_ios=$( version_for_platform $platform_iphoneos )

readonly version_ios_min="10.0"

readonly sdk_iphoneos="${platform_iphoneos}${version_ios}"
readonly sdk_simulator="${platform_simulator}${version_ios}"

readonly archs="arm64 arm64e armv7 armv7s x86_64 i386"

readonly archs_macosx="x86_64 i386"
readonly archs_ios="arm64 arm64e armv7 armv7s"
readonly archs_valid="${archs_macosx} ${archs_ios}"

readonly archive_bzip_base_url="http://www.bzip.org/${version_bzip}/"
readonly archive_name_bzip="bzip2-${version_bzip}"
readonly archive_bzip="${archive_name_bzip}.tar.gz"

readonly archive_openssl_base_url="http://www.openssl.org/source/"
readonly archive_name_openssl="openssl-${version_openssl}"
readonly archive_openssl="${archive_name_openssl}.tar.gz"

readonly archive_libarchive_base_url="http://libarchive.org/downloads/"
readonly archive_name_libarchive="libarchive-${version_libarchive}"
readonly archive_libarchive="${archive_name_libarchive}.tar.gz"

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
readonly archive_freetds="${archive_name_freetds}.tar.gz"

readonly archive_zint_base_url="https://github.com/downloads/zint/zint/"
readonly archive_name_zint="zint-${version_zint}"
readonly archive_zint="${archive_name_zint}.tar.gz"

readonly archive_png_base_url="http://prdownloads.sourceforge.net/libpng/"
readonly archive_name_png="libpng-${version_png}"
readonly archive_png="${archive_name_png}.tar.gz"

readonly path_media="$path_base/media"
readonly path_source="$path_base/source"
readonly path_library="$path_base/library"

readonly path_build="${path_base}/build"
readonly path_build_openssl="${path_build}/openssl"
readonly path_build_libarchive="${path_build}/libarchive"
readonly path_build_mysql="${path_build}/mysqlclient"
readonly path_build_zint="${path_build}/zint"
readonly path_build_tds="${path_build}/tds"
readonly path_build_png="${path_build}/libpng"
readonly path_build_unixodbc="${path_build}/unixodbc"
readonly path_build_bzip="${path_build}/bzip"

readonly path_media_ssl="$path_media/$archive_openssl"
readonly path_media_libarchive="$path_media/$archive_libarchive"
readonly path_media_mysql="$path_media/$archive_mysql"
readonly path_media_tds="$path_media/$archive_freetds"
readonly path_media_zint="$path_media/$archive_zint"
readonly path_media_png="$path_media/$archive_png"
readonly path_media_bzip="$path_media/$archive_bzip"
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

#config_make_install $version_ios $version_ios_min $arch $additional_config $path_build_tds_arch $log_build_tds $additional_work
config_make_install() { # $1=sdk-version $2=sdk-min-version $3=arch $4=additional_config $5=path_make

	printf "1: ${1}\n"
	printf "2: ${2}\n"
	printf "3: ${3}\n"
	printf "4: ${4}\n"
	printf "5: ${5}\n"
	printf "6: ${6}\n"
	printf "7: ${7}\n"

	local version_sdk=$1
	local version_sdk_min=$2
	local architecture="${3}"
	local additional_config="${4}"
	local path_make="${5}"
	local log="${6}"
	local additional_work="${7}"

	printf "%s     %s\n" "architecture" $architecture
	printf "%s%s\n" "additional_config" "${4}"
	printf "%s        %s\n" "path_make" $path_make
	printf "%s              %s\n" "log" $log
	printf "%s  %s\n" "additional_work" $additional_work

	if [[ "${4}" > 0 ]];
	then
		s="s/${additional_config_blank}//g"
		additional_config=$(echo $additional_config | sed -e $s)
		printf "Additional config is blank (%s)" $additional_config
	else
		echo "pass additional_config_blank for additional_config"
		#exit 1
	fi

	local architecture_host_part="x86_64"
	#$( uname -p )
	local architecture_host="${architecture_host_part}-apple-darwin"

	if [[ "${architecture}" == "i386" || "${architecture}" == "x86_64" ]];
	then
		if [[ "${architecture}" == "x86_64" ]];
		then
			local add_config="-m64 $(additional_config)"
		fi
		local sdk="iphonesimulator${version_sdk}"
		local architecture_target="${architecture_host_part}-apple-darwin"
	else
		local sdk="iphoneos${version_sdk}"

		if [[ "${architecture}" == "armv7" ]];
		then
			local architecture_target="${architecture}-apple-darwin"
		elif [[ "${architecture}" == "arm64" ||  "${architecture}" == "arm64e" ]];
		then
			local add_config="-m64 $(additional_config)"
			local architecture_target="arm-apple-darwin"
		else
			local architecture_target="${architecture}-apple-darwin"
		fi
	fi

	printf "%s     %s\n" "architecture" $architecture
	printf "%s%s\n" "additional_config" "${4}"
	printf "%s        %s\n" "path_make" $path_make
	printf "%s              %s\n" "log" $log
	printf "%s  %s\n" "additional_work" $additional_work

	developer_root=$( xcode-select -print-path )
	platform_root=$( xcodebuild -version -sdk $sdk PlatformPath 2>/dev/null )

	export DEVROOT="${platform_root}/Developer"
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
	printf "Configure with additional config    %s.\n" "${add_config}"
	printf "Configure with CFLAGS               %s.\n" "${CFLAGS}"
	printf "Configure with CPPFLAGS             %s.\n" "${CPPFLAGS}"

	if [[ "${#additional_config}" > 0 ]];
	then
		printf "Performing additional config"
		additional_config=$(echo $additional_config | sed -e "s/--/\ --/g")
		pwd
		./configure --host=${architecture_target} --build=${architecture_host} --target=${architecture_target} --enable-static --disable-shared --prefix="${path_make}" ${additional_config} #>> "${log}.error.log" &
		spinner $!
	else
		printf "Skipping additional config"
		./configure --host=${architecture_target} --build=${architecture_host} --target=${architecture_target} --enable-static --disable-shared --prefix="${path_make}" >> "${log}.error.log" &
		spinner $!
	fi

	if [[ "${#additional_work}" > 0 ]];
	then
		printf "Doing Extra Work"
		printf "%s %s" ${additional_work} "${path_make}"
		${additional_work} "${path_make}"
	fi

	printf "make clean"
	make clean >> "${log}.error.log" &
	spinner $!

	printf "\nmake\n"
	make  #>> "${log}.error.log"
	spinner $!

	printf "\nmake install"

	make install #>> "${log}.error.log" &
	spinner $!

	printf "\n"

} #end config_make_install()

path_source_openssl="$path_source/$archive_name_openssl"
path_source_libarchive="$path_source/$archive_name_libarchive"
path_source_mysql="$path_source/$archive_name_mysql"
path_source_tds="$path_source/$archive_name_freetds"
path_source_zint="$path_source/$archive_name_zint"
path_source_png="$path_source/$archive_name_png"
path_source_bzip="$path_source/$archive_name_bzip"
path_source_unixodbc="$path_source/$archive_name_unixodbc"
path_source_classpath="$path_source/$archive_name_classpath"
path_source_glib="$path_source/$archive_name_glib"
path_source_autoconf="$path_source/$archive_name_autoconf"
path_source_automake="$path_source/$archive_name_automake"
path_source_autoconf="$path_source/$archive_name_acl"
path_source_automake="$path_source/$archive_name_attr"

mkdir -p media;

# Download source if it doesn’t exist
download_archive $archive_glib          $archive_glib_base_url
download_archive $archive_classpath     $archive_classpath_base_url
download_archive $archive_openssl       $archive_openssl_base_url
download_archive $archive_mysql         $archive_mysql_base_url
download_archive $archive_freetds       $archive_freetds_base_url
download_archive $archive_zint          $archive_zint_base_url
download_archive $archive_png           $archive_png_base_url
download_archive $archive_bzip          $archive_bzip_base_url
download_archive $archive_libarchive    $archive_libarchive_base_url

cd "${path_base}"

rm -rf -- source
mkdir -p source
mkdir -p library

counter_arch=0

platform="iphoneos"

readonly config_debug="Debug"
readonly config_release="Release"
readonly command_lipo_create="lipo -create "

# UnixODBC
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

# OpenSSL
path_library_openssl="${path_library}/openssl"
if [[ $build_openssl == $true && $show_help == $false ]]; then

	command_lipo_libcrypto="${command_lipo_create}"
	command_lipo_libssl="${command_lipo_create}"

	printf "Libcrypto: ${command_lipo_libcrypto}"

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

		printf "%s:\t\t%s\n" "CROSS_TOP" "${env_cross_top}"
		printf "%s:\t\t%s\n" "CROSS_SDK" "${env_cross_sdk}"
		printf "%s:\t\t%s\n" "BUILD_TOOLS" "${env_build_tools}"
		printf "%s:\t\t%s\n" "CC" "${env_cc}"

		printf "%s\n\t%s\n\t%s\n" "Extracting source" $path_media_ssl $path_source
		extract_source $path_media_ssl $path_source

		# Compiling OpenSSL
		cd "${path_source_openssl}"

		if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
		then
			printf ""
		else
			sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
		fi

		platform_version_arch="${platform}${version_ios}-${arch}"
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

		printf "Building OpenSSL.\n"
		printf "./Configure --openssldir=${path_build_openssl_arch}"
		> "$log_build_openssl"

		printf "Building OpenSSL.\n"

		set +e

		if [[ "${arch}" == "x86_64" ]]; then
			./Configure darwin64-x86_64-cc --openssldir="${path_build_openssl_arch}" > "${log_build_openssl}" 2>&1
		elif [ "${arch}" == "i386" ]; then
			./Configure BSD-generic32 --openssldir="${path_build_openssl_arch}" > "${log_build_openssl}" 2>&1
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

# MySQL Connector - Comp_err OS X swizzle - Correct way to do it.
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
			cmake -DOPENSSL_ROOT_DIR=$path_library_openssl -Wno-dev -GXcode # >> $log_build_mysql &
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

# PNG
if [[ $build_png == $true  && $show_help == $false ]]; then

	set -e
	printf "Starting PNG\n"
	printf "\-\-\-\-\-\-\-\-\-\-\-\-\n\n"

	command_lipo_png="${command_lipo_create}"
	path_library_png="${path_library}/libpng"

	additional_config=""

	for arch in ${archs}
	do
		platform=$( platform_for_architecture arch )
		printf "\n\nBuilding libpng for %s %s." "${arch}" "${platform}"

		if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
		then
			platform="iPhoneSimulator"
			additional_config="--enable-arm-neon=no "
		else
			platform="iPhoneOS"
			additional_config="--enable-arm-neon=yes "
		fi

		platform_version_arch="${platform}${version_ios}-${arch}"
		path_build_png_arch="${path_build_png}/$platform_version_arch.sdk"

		printf "Extracting libpng source code.\n"
		rm -rf -- "${path_source_png}"
		mkdir -p "${path_source_png}"
		tar zxf ${path_media_png} -C ${path_source}

		platform_version_arch="${platform}${version_ios}-${arch}"
		path_build_unixodbc_arch="${path_build_png}/$platform_version_arch.sdk"

		printf "Make directory build_png_arch\n";
		mkdir -p "${path_build_png_arch}"
		rm -rf -- "${path_build_png_arch}"
		printf "Make directory build_png_arch again\n";
		mkdir -p "${path_build_png_arch}"
		log_build_png="${path_build_png}/build-libpng-${version_png}-${arch}.log"
		> "$log_build_png"

		cd "${path_base}"

		printf "Extract source.\n"
		extract_source $path_media_png $path_source &
		spinner $!

		printf "Changing to source directory.\n"

		cd "${path_source_png}"
		export CFLAGS=""
		export CPPFLAGS=""

		printf "lipo\n"
		command_lipo_png="${command_lipo_png} ${path_build_png_arch}/lib/libpng.a"

		printf "config_make_install\n\t" "${arch}" "${path_build_png_arch}" "${log_build_png}"

		config_make_install $version_ios $version_ios_min $arch $additional_config $path_build_png_arch $log_build_png # $1=sdk-version $2=sdk-min-version $3=arch $4=additionalConfig $5=make-path $6=log-path

	done

	printf "mkdir -p" "${path_library_png}"
	mkdir -p "${path_library_png}"
	rm -rf -- "${path_library_png}"
	mkdir -p "${path_library_png}"

	cp -R "${path_build_png_arch}/include" "${path_library_png}"
	command_lipo_png="${command_lipo_png} -output ${path_library_png}/libpng16.a"
	ln -s "${path_library_png}/libpng16.a" "${path_library_png}/libpng.a"
	$command_lipo_png
fi

# bzip2 - build when libarchive is built
if [[ $false && $build_libarchive == $true  && $show_help == $false ]]; then

	set -e

	command_lipo_bzip="${command_lipo_create}"
	command_lipo_ct="${command_lipo_create}"
	path_library_bzip="${path_library}/bzip"

	for arch in ${archs}
	do
		platform=$( platform_for_architecture arch )

		printf "\n\nBuilding bzip for %s %s." "${arch}" "${platform}"

		platform_version_arch="${platform}${version_ios}-${arch}"
		path_build_bzip_arch="${path_build_bzip}/$platform_version_arch.sdk"

		printf "mkdir %s\n" "${path_build_bzip_arch}"

		mkdir -p "${path_build_bzip_arch}"
		rm -rf -- "${path_build_bzip_arch}"
		mkdir -p "${path_build_bzip_arch}"
		log_build_bzip="${path_build_bzip}/build-bzip-${version_bzip}-${arch}.log"
		> "$log_build_bzip"

		cd "${path_base}"

		extract_source $path_media_bzip $path_source &
		spinner $!

		cd "${path_source_bzip}"
		export CFLAGS=""
		export CPPFLAGS=""

		command_lipo_bzip="${command_lipo_bzip} ${path_build_bzip_arch}/lib/bzip.a"
		command_lipo_ct="${command_lipo_ct} ${path_build_bzip_arch}/lib/libct.a"
		additional_config="${additional_config_blank}"
		additional_work=""

		printf "config_make_install %s\n\t\t%s\n\t\t%s\n\t\t%s" "${version_ios}" "${version_ios_min}" "${additional_config}" "${path_build_bzip_arch}"

		config_make_install $version_ios $version_ios_min $arch $additional_config $path_build_bzip_arch $log_build_bzip $additional_work

	done
fi

# libarchive
if [[ $build_libarchive == $true  && $show_help == $false ]]; then

	set -e

	command_lipo_libarchive="${command_lipo_create}"
	command_lipo_ct="${command_lipo_create}"
	path_library_libarchive="${path_library}/libarchive"

	for arch in ${archs}
	do
		platform=$( platform_for_architecture arch )

		printf "\n\nBuilding Libarchive for %s %s." "${arch}" "${platform}"

		platform_version_arch="${platform}${version_ios}-${arch}"
		path_build_libarchive_arch="${path_build_libarchive}/$platform_version_arch.sdk"

		mkdir -p "${path_build_libarchive_arch}"
		rm -rf -- "${path_build_libarchive_arch}"
		mkdir -p "${path_build_libarchive_arch}"
		log_build_libarchive="${path_build_libarchive}/build-libarchive-${version_libarchive}-${arch}.log"
		> "$log_build_libarchive"

		cd "${path_base}"

		extract_source $path_media_libarchive $path_source &
		spinner $!

		cd "${path_source_libarchive}"
		export CFLAGS=""
		export CPPFLAGS=""

		command_lipo_libarchive="${command_lipo_libarchive} ${path_build_libarchive_arch}/lib/libarchive.a"
		additional_config="${additional_config_blank}"
		additional_work=""

		config_make_install $version_ios $version_ios_min $arch $additional_config $path_build_libarchive_arch $log_build_libarchive $additional_work

	done
fi

# TDS
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

		printf "mkdir %s\n" "${path_build_tds_arch}"

		sudo mkdir -p "${path_build_tds_arch}"
		printf "rm-rf" "${path_build_tds_arch}"
		sudo mkdir -p "${path_build_tds_arch}"
		sudo mkdir -p "{$path_source}"
		log_build_tds="${path_build_tds}/build-tds-${version_freetds}-${arch}.log"
		printf "cd ${path_base}"
		cd "${path_base}"

		extract_source $path_media_tds $path_source &
		spinner $!

		cd "${path_source_tds}"

		command_lipo_tds="${command_lipo_tds} ${path_build_tds_arch}/lib/libsybdb.a"
		command_lipo_ct="${command_lipo_ct} ${path_build_tds_arch}/lib/libct.a"
		additional_config=" --with-tdsver=${version_tds} " #--with-openssl=/Users/michael/Desktop/Reports/Compressor/library/openssl"
		additional_work="addtional_work_libsybdb"

		config_make_install "${version_ios}" "${version_ios_min}" "${arch}" "${additional_config}" "${path_build_tds_arch}" "${log_build_tds}" "${additional_work}"

	done
fi

# ZINT
# Unfinished... Included in code.
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

printf "Compressor is done.\n"
