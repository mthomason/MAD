#!/bin/sh

# Created Michael Thomason for Everyday Apps LLC on Jan 24, 2014.

print_help() {
   printf "  %s\n"  "Usage: compressor [options] ..."
   printf "  %s\n" "--openssl                Build OpenSSL.\n"
   printf "  %s\n" "--freetds                Build FreeTds.\n"
   printf "  %s\n" "--libpng                 Build libpng.\n"
   printf "  %s\n" "--mysql                  Build MySQL Connector.\n"
   printf "  %s\n" "-h,--help                Show help.\n"
}

#
# Globals
#

readonly true=0
readonly false=1

readonly version_openssl="1.0.1f"
readonly version_mysql="6.1.3"
#readonly version_freetds="stable"
readonly version_freetds="0.91"
readonly version_tds=7.1
readonly version_zint="2.4.2"
readonly version_png="1.6.8"

readonly version_mysql_6_0="6.0.2"  #do not change
readonly version_mysql_6_1="6.1.3"

readonly version_macosx=$( xcodebuild -version -sdk macosx SDKVersion 2>/dev/null )
readonly version_ios=$( xcodebuild -version -sdk iphoneos SDKVersion 2>/dev/null )
readonly version_ios_min=$version_ios

readonly platform_iphoneos="iphoneos"
readonly platform_simulator="iphonesimulator"
readonly platform_macosx="macosx"
readonly sdk_iphoneos="${platform_iphoneos}${version_ios}"
readonly sdk_simulator="${platform_simulator}${version_ios}"

readonly archs="i386 armv7 armv7s arm64"
readonly archs_macosx="i386 x86_64"
readonly archs_ios="armv7 armv7s arm64"
readonly archs_valid="${archs_macosx} ${archs_ios}"

readonly archive_openssl_base_url="http://www.openssl.org/source/"
readonly archive_name_openssl="openssl-${version_openssl}"
readonly archive_openssl="${archive_name_openssl}.tar.gz"

readonly archive_mysql_base_url="http://dev.mysql.com/get/Downloads/Connector-C/"
if [[ "${version_mysql}" == "${version_mysql_6_0}" ]]
then
   readonly archive_name_mysql="mysql-connector-c-${version_mysql}"
else
   readonly archive_name_mysql="mysql-connector-c-${version_mysql}-src"
fi
readonly archive_mysql="${archive_name_mysql}.tar.gz"

readonly archive_freetds_base_url="ftp://ftp.freetds.org/pub/freetds/stable/"
readonly archive_name_freetds="freetds-${version_freetds}"
readonly archive_freetds="freetds-stable.tgz"

readonly archive_zint_base_url="https://github.com/downloads/zint/zint/"
readonly archive_name_zint="zint-${version_zint}"
readonly archive_zint="${archive_name_zint}.tar.gz"

readonly archive_png_base_url="ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/"
readonly archive_name_png="libpng-${version_png}"
readonly archive_png="${archive_name_png}.tar.gz"

readonly path_base=$( pwd )
readonly path_media="$path_base/media"
readonly path_source="$path_base/source"
readonly path_library="$path_base/library"

readonly path_media_ssl="$path_media/$archive_openssl"
readonly path_media_mysql="$path_media/$archive_mysql"
readonly path_media_tds="$path_media/$archive_freetds"
readonly path_media_zint="$path_media/$archive_zint"
readonly path_media_png="$path_media/$archive_png"

readonly path_gcc=$( xcrun -find gcc )
readonly path_clang=$( xcrun -find clang )

build_openssl=$false
build_png=$false
build_mysql=$false
build_mysql_ios7=$false
build_tds=$false
build_zint=$false
show_help=$false

#
# Functions
#

formatting_divider="####################"
formatting_divider=$formatting_divider$formatting_divider$formatting_divider$formatting_divider

spinner() {
   local pid=$1
   local delay=0.66
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

#
# Process flags
#

if [[ $# == 0 ]];
then
   show_help=$true
fi

while [[ $# > 0 ]]
do
   key="$1"
   shift

   case $key in
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
fi


#
# Download missing source archives
#

download_archive() { # $1=archive name; $2=archive url
   if [ ! -e media/${1} ]; then
      cd media && { curl -L -O ${2}${1} ; cd - ; }
   fi
}

#
# Extract archives
#

extract_source() {
   echo "Extracting source"
   local archive=$1
   local destination=$2
   sudo rm -rf -- "${destination}"
   mkdir -p "${destination}"
   tar zxf ${archive} -C ${destination}
}

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
path_build_tds="${path_build}/tds"
path_build_png="${path_build}/libpng"

path_xcode=`xcode-select -print-path`

path_sdk_root_iPhoneOS=$( xcodebuild -version -sdk iphoneos Path 2>/dev/null )
path_sdk_root_iPhoneSimulator=$( xcodebuild -version -sdk iphonesimulator Path 2>/dev/null )
path_sdk_root_MacOSX=$( xcodebuild -version -sdk macosx Path 2>/dev/null )

config_make_install() { # $1=sdk-version $2=sdk-min-version $3=arch $4=additional_config $5=path_make $6=addtional_work

   local version_sdk=$1
   local version_sdk_min=$2
   local architecture=$3
   local additional_config=$4
   local path_make=$5
   local addtional_work=$6

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

   if [[ "${#additional_word}" > 0 ]];
   then
      $( "${addtional_work} $path_make" )
   fi

   if [[ "${#additional_config}" > 0 ]];
   then
      ./configure --host=${architecture_host} --build=${architecture_target} --target=${architecture_target} --enable-static --disable-shared --prefix=${path_make} ${additional_config} >> log  &
      spinner $!
   else
      ./configure --host=${architecture_host} --build=${architecture_target} --target=${architecture_target} --enable-static --disable-shared --prefix=${path_make} >> log  &
      spinner $!
   fi

   printf "\nmake clean"
   make clean >> log 2>&1 &
   spinner $!

   printf "\nmake"
   make >> log &
   spinner $!

   make install >> log 2>&1 &
   spinner $!

}

addtional_work_libsybdb() {
   local path_make=$1

   sed -i '' 's/#define HAVE_ICONV 1/#define HAVE_ICONV 0/g' ${path_make}/include/config.h
}

path_source_openssl="$path_source/$archive_name_openssl"
path_source_mysql="$path_source/$archive_name_mysql"
path_source_tds="$path_source/$archive_name_freetds"
path_source_zint="$path_source/$archive_name_zint"
path_source_png="$path_source/$archive_name_png"

mkdir -p media;

#
# Download source if it doesn’t exist
#

download_archive $archive_openssl $archive_openssl_base_url
download_archive $archive_mysql $archive_mysql_base_url
download_archive $archive_freetds $archive_freetds_base_url
download_archive $archive_zint $archive_zint_base_url
download_archive $archive_png $archive_png_base_url

cd "${path_base}"

rm -rf -- source
mkdir -p source
mkdir -p library

counter_arch=0

platform="iphoneos"

#
# OpenSSL
#

if [[ $build_openssl == $true && $show_help == $false ]]; then

   command_lipo_libcrypto="lipo -create "
   command_lipo_libssl="lipo -create "

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
       sudo rm -rf -- "${path_build_openssl_arch}"
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

   path_library_openssl="${path_library}/openssl-${version_openssl}-iphoneos${version_ios}"

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

fi

#
# MySQL Connector (OS X Hack)
#

if [[ $build_mysql == $true  && $show_help == $false ]]; then

   command_lipo_mysql="lipo -create "
   path_library_mysql="${path_library}/libmysql-${version_mysql}-iphoneos${version_ios}"

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

      sudo xcodebuild -project libmysql.xcodeproj -target mysqlclient -configuration Release -sdk "${sdk_build}" ONLY_ACTIVE_ARCH=NO ARCHS="$arch" VALID_ARCHS="${archs_valid}" PRODUCT_NAME=${product_name_mysql} >> $log_build_mysql &
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
# MySQL Connector - Michael Thomason build
#

if [[ $build_mysql_ios7 == $true  && $show_help == $false ]]; then


   # Build for native platform, so we can get the comp_err program.
   #  The comp_error must run for error messages to be generated for
   #  the libs, but since the libs are armv, we need to do a native
   #  generation of this helper application.



   command_lipo_mysql="lipo -create "
   path_library_mysql="${path_library}/libmysql-${version_mysql}-iphoneos${version_ios}"

   path_source_mysql_native="${path_source}/native"

   mkdir -p "${path_source_mysql_native}"
   rm -rf -- "${path_source_mysql_native}"
   mkdir -p "${path_source_mysql_native}"
   tar zxf ${path_media_mysql} -C ${path_source_mysql_native}

   pushd ${path_source_mysql_native}/${archive_name_mysql}
   mkdir -p "${path_build_mysql}"
   log_build_mysql="${path_build_mysql}/build-mysql-native-release.log"

   cmake -Wno-dev -GXcode >> $log_build_mysql &
   spinner $!

   sed -ie 's/compile_time_assert(sizeof(LF_PINS) == 64);/\/\/compile_time_assert(sizeof(LF_PINS) == 64);/g' 'mysys/lf_alloc-pin.c'

   xcodebuild -project LibMySQL.xcodeproj  -target mysqlclient -configuration Release -sdk macosx${version_macosx} ONLY_ACTIVE_ARCH=NO ARCHS="${archs_macosx}" >> $log_build_mysql &
   spinner $!


   popd

   for platform in $platform_iphoneos $platform_simulator
   do

      if [ "${platform}" == "${platform_iphoneos}" ]
      then
         sdk_build=${sdk_iphoneos}
         archs_to_build="armv7 armv7s arm64"
      else
         sdk_build=${sdk_simulator}
         archs_to_build="i386 x86_64"
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

      cmake -Wno-dev -GXcode >> $log_build_mysql &
      spinner $!

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

      if xcodebuild -project LibMySQL.xcodeproj  -target mysqlclient -configuration Release -sdk ${sdk_build} ONLY_ACTIVE_ARCH=NO ARCHS="${archs_to_build}" VALID_ARCHS="${archs_valid}" >> $log_build_mysql
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
         cp -r extra/yassl/Release-$platform extra/yassl/Release
         cp -r extra/yassl/taocrypt/Release-$platform extra/yassl/taocrypt/Release
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

   exit 0

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

   command_lipo_png="lipo -create "
   path_library_png="${path_library}/libpng-${version_png}-iphoneos${version_ios}"

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
      sudo rm -rf -- "${path_build_png_arch}"
      log_build_png="${path_build_png}/build-libpng-${version_png}-${arch}.log"
      > "$log_build_png"

      cd "${path_base}"

      extract_source $path_media_png $path_source &
      spinner $!

      cd "${path_source_png}"

      command_lipo_png="${command_lipo_png} ${path_build_png_arch}/lib/libpng.a"



      config_make_install $version_ios $version_ios_min $arch $additional_config $path_build_png_arch $log_build_png # $1=sdk-version $2=sdk-min-version $3=arch $4=additionalConfig $5=make-path $6=log-path

      unset $additional_config
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

   command_lipo_tdstds="lipo -create "

   for arch in ${archs}
   do
      if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
      then
         platform="iPhoneSimulator"
      else
         platform="iPhoneOS"
      fi

      platform_version_arch="${platform}${version_ios}-${arch}"
      path_build_tds_arch="${path_build_tds}/$platform_version_arch.sdk"

      mkdir -p "${path_build_tds_arch}"
      sudo rm -rf -- "${path_build_tds_arch}"
      mkdir -p "${path_build_tds_arch}"
      log_build_tds="${path_build_tds}/build-tds-${version_freetds}-${arch}.log"
      > "$log_build_tds"

      cd "${path_base}"

      extract_source $path_media_tds $path_source &
      spinner $!

      cd "${path_source_tds}"

      command_lipo_tds="${command_lipo_tds} ${path_build_tds_arch}/lib/libsysdb.a"
      additional_config=" -with-tdsver=${TDS_VER} "

      config_make_install $version_ios $version_ios_min $arch $additional_config $path_build_tds_arch $log_build_tds # $1=sdk-version $2=sdk-min-version $3=arch $4=additionalConfig $5=make-path $6=log-path


   done

   mkdir -p "${path_library_tds}"
   rm -rf -- "${path_library_tds}"
   mkdir -p "${path_library_tds}"

   cp -R "${path_build_tds_arch}/include" "${path_library_tds}"
   command_lipo_tds="${command_lipo_tds} -output ${path_library_tds}/libsysdb.a"
   $command_lipo_tds

fi

#
# ZINT
#

if [[ $build_zint == $true  && $show_help == $false ]]; then

   command_lipo_zint="lipo -create "

   for arch in ${archs}
   do
      if [[ "${arch}" == "i386" || "${arch}" == "x86_64" ]];
      then
         platform="iPhoneSimulator"
      else
         platform="iPhoneOS"
      fi
   done

   printf "Extracting Zint source code.\n"
   rm -rf -- "${path_source_zint}"
   mkdir -p "${path_source_zint}"
   tar zxf ${path_media_zint} -C ${path_source}

   platform_version_arch="${platform}${version_ios}-${arch}"
   path_build_zint_arch="${path_build_zint}/$platform_version_arch.sdk"

   mkdir -p "${path_build_zint_arch}"
   sudo rm -rf -- "${path_build_zint_arch}"
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

sudo rm -rf -- "${path_build}"
sudo rm -rf -- "${path_source}"

printf "Compressor is done.\n"
