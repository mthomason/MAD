#!/bin/sh

# Created Michael Thomason for Everyday Apps LLC on Jan 24, 2014.

formatting_divider="####################"
formatting_divider=$formatting_divider$formatting_divider$formatting_divider$formatting_divider

#debug=true;

#
# Get options
#

while getopts d options
do
   case "$options" in
      d) debug=true;;
   esac
done

version_ios="7.0"
version_ios_min="7.0"
archs="i386 armv7 armv7s arm64"
#x86_64

sdk_iphoneos="iphoneos${version_ios}"
sdk_simulator="iphonesimulator${version_ios}"

version_macos="10.9"

version_openssl="1.0.1f"
version_mysql="6.0.2"
#"6.1.3"#"6.0.2"
version_freetds="stable"
version_zint="2.4.2"
version_png="1.6.8"

version_mysql_6_0="6.0.2"
version_mysql_6_1="6.1.3"

archive_openssl_base_url="http://www.openssl.org/source/"
archive_name_openssl="openssl-${version_openssl}"
archive_openssl="${archive_name_openssl}.tar.gz"


archive_mysql_base_url="http://dev.mysql.com/get/Downloads/Connector-C/"
if [[ "${version_mysql}" == "${version_mysql_6_0}" ]]
then
   archive_name_mysql="mysql-connector-c-${version_mysql}"
else
   archive_name_mysql="mysql-connector-c-${version_mysql}-src"
fi
archive_mysql="${archive_name_mysql}.tar.gz"

printf "${archive_mysql}\n"

archive_freetds_base_url="ftp://ftp.freetds.org/pub/freetds/stable/"
archive_name_freetds="freetds-${version_freetds}"
archive_freetds="${archive_name_freetds}.tgz"

archive_zint_base_url="https://github.com/downloads/zint/zint/"
archive_name_zint="zint-${version_zint}"
archive_zint="${archive_name_zint}.tar.gz"

archive_png_base_url="ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/"
archive_name_png="libpng-${version_png}"
archive_png="${archive_name_png}.tar.gz"

path_base=`pwd`
path_media="$path_base/media"
path_source="$path_base/source"
path_library="$path_base/library"

path_gcc=$( xcrun -find gcc )
path_clang=$( xcrun -find clang )

case $path_base in # Check if current path contains whitespace.
   *\ * )
   printf "ABORT: Current path has whitespace.\n"
   exit 1
   ;;
   esac

path_build="${path_base}/build"
path_build_openssl="${path_build}/openssl"
path_build_mysql="${path_build}/mysqlclient"
path_build_zint="${path_build}/zint"
path_build_freetds="${path_build}/freetds"
path_build_png="${path_build}/libpng"

path_xcode=`xcode-select -print-path`

path_sdk_root_iPhoneOS="${path_xcode}/Platforms/iPhoneOS.platform/Developer/iPhoneOS${version_ios}.sdk"
path_sdk_root_iPhoneSimulator="${path_xcode}/Platforms/iPhoneSimulator.platform/Developer/iPhoneSimulator${version_ios}.sdk"
path_sdk_root_MacOSX="${path_xcode}/Platforms/MacOSX.platform/Developer/MacOSX${version_macos}.sdk"

path_sdk_root_iPhoneOS="${path_xcode}/Platforms/iPhoneOS.platform/Developer"
path_sdk_root_iPhoneSimulator="${path_xcode}/Platforms/iPhoneSimulator.platform/Developer"
path_sdk_root_MacOSX="${path_xcode}/Platforms/MacOSX.platform/Developer"

#
# Functions
#

spinner() {
   local pid=$1
   local delay=0.75
   local spinstr='|/-\'
   while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
      local temp=${spinstr#?}
      s=$(printf " [%c]  " "$spinstr")
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

download_archive() { # $1=archive name; $2=archive url
   set -e
   if [ ! -e media/${1} ]; then
      printf "\n%s\nDownloading %s.\n" "$formatting_divider" "$1"
      cd media && { curl -L -O ${2}${1} ; cd - ; }
      printf "\n%s\n" "$formatting_divider"
   else
      printf "Using media/%s.\n" "$1"
   fi
}

make_libpng() { # $1=sdk-version $2=sdk-min-version $3=arch $4=make-function

   local version_sdk=$1
   local version_sdk_min=$2
   local architecture=$3
   local path_make=$5

   local architecture_host_part=$( uname -p )
   local architecture_host="${architecture_host_part}-apple-darwin"

   if [[ "${architecture}" == "i386" || "${architecture}" == "x86_64" ]];
   then
      local sdk="iphonesimulator${version_sdk}"
      local arm_neon="--enable-arm-neon=no"
      local architecture_target="${architecture_host_part}-apple-darwin"
   else
      local sdk="iphoneos${version_sdk}"

      if [[ "${architecture}" == "armv7" ]];
      then
         local arm_neon="--enable-arm-neon=no"
         local architecture_target="${architecture}-apple-darwin"
      elif [[ "${architecture}" == "arm64" ]];
      then
         local arm_neon="--enable-arm-neon=yes"
         local architecture_target="arm-apple-darwin"
      else
         local arm_neon="--enable-arm-neon=yes"
         local architecture_target="${architecture}-apple-darwin"
      fi

   fi

   developer_root=$( xcode-select -print-path )
   platform_root=$( xcodebuild -version -sdk $sdk PlatformPath 2>/dev/null )
   export DEVROOT="${platform_root}/Developer"
   export SDKROOT=$( xcodebuild -version -sdk $sdk Path 2>/dev/null )
   export CC=$( xcrun -find gcc )
   export CFLAGS="-arch ${architecture} -isysroot ${SDKROOT} -I${SDKROOT}/usr/include -miphoneos-version-min=${version_sdk_min}"
   export LD=$( xcrun -find ld )
   export LDFLAGS="-arch ${architecture} -isysroot ${SDKROOT} -L${SDKROOT}/usr/lib -miphoneos-version-min=${version_sdk_min}"
   export CPPFLAGS="-arch ${architecture} -isysroot ${SDKROOT} -I${SDKROOT}/usr/include"
   echo ""
   printenv
   echo ""

   ./configure --host=${architecture_host} --build=${architecture_target} --target=${architecture_target} --enable-static --disable-shared --prefix=${path_make} ${arm_neon} >> log
   make clean >> log
   make -j4 >> log
   make install >> log

}

path_media_ssl="$path_media/$archive_openssl"
path_media_mysql="$path_media/$archive_mysql"
path_media_freetds="$path_media/$archive_freetds"
path_media_zint="$path_media/$archive_zint"
path_media_png="$path_media/$archive_png"

path_source_openssl="$path_source/$archive_name_openssl"
path_source_mysql="$path_source/$archive_name_mysql"
path_source_freetds="$path_source/$archive_name_freetds"
path_source_zint="$path_source/$archive_name_zint"
path_source_png="$path_source/$archive_name_png"

printf "\n%s\n" "$formatting_divider"
printf "Current Path:     %s\n" "$path_base"
printf "Xcode Path:       %s\n" "$path_xcode"
printf "Architectures:    %s\n" "$archs"
printf "iOS Version:      %s\n" "$version_ios"

printf "\n"

printf "OpenSSL Version:  %s\n" "$version_openssl"
printf "OpenSSL Archive:  %s\n" "$path_media_ssl"
printf "OpenSSL Source:   %s\n" "$path_source_openssl"

printf "\n"

printf "MySQL Version:    %s\n" "$version_mysql"
printf "MySQL Archive:    %s\n" "$path_media_mysql"
printf "MySQL Source:     %s\n" "$path_source_mysql"

printf "\n"

printf "Free Tds Version: %s\n" "$version_freetds"
printf "Free Tds Archive: %s\n" "$path_media_freetds"
printf "Free Tds Source:  %s\n" "$path_source_freetds"

printf "\n"

printf "Zint Version:     %s\n" "$version_zint"
printf "Zint Archive:     %s\n" "$path_media_zint"
printf "Zint Source:      %s\n" "$path_source_zint"

printf "%s\n\n" "$formatting_divider"
printf "%s\n" "$formatting_divider"

if [ ! -d media ]; then
   printf "Creating media directory.\n"
   mkdir media;
else
   printf "Using cached media directory.\n"
fi

#
# Download source if it doesn’t exist
#

download_archive $archive_openssl $archive_openssl_base_url
download_archive $archive_mysql $archive_mysql_base_url
download_archive $archive_freetds $archive_freetds_base_url
download_archive $archive_zint $archive_zint_base_url
download_archive $archive_png $archive_png_base_url

printf "Media assumed.\n"

cd "${path_base}"

sudo rm -rf -- source

if [ ! -d source ]; then
   printf "Creating source directory.\n"
   mkdir source;
else
   printf "Using cached source directory.\n"
fi

#sudo rm -rf -- library

if [ ! -d library ]; then
   printf "Creating library directory.\n"
   mkdir library;
else
   printf "Using cached library directory.\n"
fi

printf "%s\n\n" "$formatting_divider"

command_lipo_libcrypto="lipo -create "
command_lipo_libssl="lipo -create "
command_lipo_mysql="lipo -create "
command_lipo_png="lipo -create "

counter_arch=0

platform="iphoneos"

for arch in ${archs}
do

   printf "\n%s\n" "$formatting_divider"

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

   printf "export CROSS_TOP=%s\n" "${env_cross_top}"
   printf "export CROSS_SDK=%s\n" "${env_cross_sdk}"
   printf "export BUILD_TOOLS=%s\n" "${env_build_tools}"
   printf "export CC=%s" "${env_cc}" 

   export CROSS_TOP="${env_cross_top}"
   export CROSS_SDK="${env_cross_sdk}"
   export BUILD_TOOLS="${env_build_tools}"
   export CC="${env_cc}"

   if [[ "$debug" ]]; then

      printf "Skipping Extration.\n"

   else

      printf "Extracting OpenSSL source code.\n"
      sudo rm -rf -- "${path_source_openssl}"
      tar zxf ${path_media_ssl} -C ${path_source}

      printf "Extracting FreeTds source code.\n"
      rm -rf -- "${path_source_freetds}"
      tar zxf ${path_media_freetds} -C ${path_source}

      printf "Extracting Zint source code.\n"
      rm -rf -- "${path_source_zint}"
      tar zxf ${path_media_zint} -C ${path_source}



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
       sudo rm -rf -- "${path_build_openssl_arch}"
       mkdir -p "${path_build_openssl_arch}"

       log_build_openssl="${path_build_openssl_arch}/build-openssl-${version_openssl}.log"

       > "$log_build_openssl"

       if [[ "$debug" ]]; then

          printf "Skipping OpenSSL build.\n"

       else

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

       fi


   fi

done

# Cleanup Openssl

path_library_openssl="${path_library}/openssl-${version_openssl}-iphoneos${version_ios}"
path_library_mysql="${path_library}/libmysql-${version_mysql}-iphoneos${version_ios}"
path_library_png="${path_library}/libpng-${version_png}-iphoneos${version_ios}"

rm -rf "${path_library_openssl}"

mkdir -p "${path_library_openssl}"

if [[ "$debug" ]]; then
   printf "Skipping combine.\n"
else

   command_lipo_libcrypto="${command_lipo_libcrypto} -output ${path_library_openssl}/libcrypto.a"
   $command_lipo_libcrypto

   command_lipo_libssl="${command_lipo_libssl} -output ${path_library_openssl}/libssl.a"
   $command_lipo_libssl

   path_build_openssl_arch_include=${path_build_openssl_arch}/include
   path_library_openssl_include=${path_library_openssl}
   mkdir -p ${path_library_openssl_include}

   cp -R $path_build_openssl_arch_include $path_library_openssl

fi

mkdir -p "${path_build_mysql}"

#
# Compiling MySQL Connector
#

if [[ "$debug" ]]; then

   printf "Skipping MySQL build.\n"

else

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
       sudo rm -rf -- "${path_source_mysql}"
       mkdir -p "${path_source_mysql}"
       tar zxf ${path_media_mysql} -C ${path_source}

       cd "${path_source_mysql}"

       archs_cmake=$(echo $archs | sed -e "s/ /\\;/g")

       sysroot="${path_xcode}/Platforms/${platform}.platform/Developer/SDKs/iPhoneOS${version_ios}.sdk"

       printf "Configuring MySQL\n"

       sudo cmake -GXcode >> $log_build_mysql &
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

      sudo xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk "${sdk_build}" ONLY_ACTIVE_ARCH=NO ARCHS="$arch" VALID_ARCHS="i386 x86_64 armv7 armv7s arm64" PRODUCT_NAME=${product_name_mysql} >> $log_build_mysql &
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

#if [[ "$debug" ]]; then
#   printf "Skipping PNG build.\n"
#else

for arch in ${archs}
do
   if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
   then
      platform="iPhoneSimulator"
   else
      platform="iPhoneOS"
   fi

   platform_version_arch="${platform}${version_ios}-${arch}"
   path_build_png_arch="${path_build_png}/$platform_version_arch.sdk"

   mkdir -p "${path_build_png_arch}"
   sudo rm -rf -- "${path_build_png_arch}"
   log_build_png="${path_build_png}/build-libpng-${version_png}-${arch}.log"
   > "$log_build_png"

   cd "${path_base}"

   printf "Extracting PNG source code.\n"
   sudo rm -rf -- "${path_source_png}"
   tar zxf ${path_media_png} -C ${path_source}

   pf="${path_build_png}/"
   cd "${path_source_png}"

   command_lipo_png="${command_lipo_png} ${path_build_png_arch}/lib/libpng.a"

   make_libpng $version_ios $version_ios_min $arch "make_libpng" $path_build_png_arch $log_build_png # $1=sdk-version $2=sdk-min-version $3=arch $4=make-function $5=make-path $6=log-path

   printf "DONE\n\n"

done


mkdir -p "${path_library_png}"
sudo rm -rf -- "${path_library_png}"
mkdir -p "${path_library_png}"

printf "\n\ncp -R \"${path_build_png_arch}/include\" \"${path_library_png}\"\n\n"

cp -R "${path_build_png_arch}/include" "${path_library_png}"
command_lipo_png="${command_lipo_png} -output ${path_library_png}/libpng16.a"
ln -s "${path_library_png}/libpng16.a" "${path_library_png}/libpng.a"
$command_lipo_png

#cleanup
sudo rm -rf -- "${path_build}"
sudo rm -rf -- "${path_source}"

printf "Compressor is done.\n"

