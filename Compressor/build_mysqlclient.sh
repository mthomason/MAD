#!/bin/bash

set -e
set -u
set -o pipefail

MYSQL_VERSION="8.0.42"
EXPECTED_BOOST_VERSION="1.77.0"
EXPECTED_BOOST_DIR_NAME="boost_${EXPECTED_BOOST_VERSION//./_}" # Replaces . with _ -> boost_1_77_0

BASE_WORK_DIR="/Users/michael/Desktop/Reports/Compressor"
MEDIA_DIR="${BASE_WORK_DIR}/media"
SRC_DIR="${BASE_WORK_DIR}/src"
BUILD_PARENT_DIR="${BASE_WORK_DIR}/build"
LIBRARY_DIR="${BASE_WORK_DIR}/library"


OPENSSL_INCLUDE="${LIBRARY_DIR}/openssl/include"
OPENSSL_LIBS=("${LIBRARY_DIR}/openssl/lib/iOS")

CMAKE_SUBDIR_NAME="mysql_iphoneos"
CMAKE_WORK_DIR="${BUILD_PARENT_DIR}/${CMAKE_SUBDIR_NAME}"

MYSQL_URL="https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-boost-${MYSQL_VERSION}.tar.gz"
TARBALL_NAME="mysql-boost-${MYSQL_VERSION}.tar.gz"
TARBALL_PATH="${MEDIA_DIR}/${TARBALL_NAME}"

EXPECTED_SOURCE_SUBDIR="mysql-${MYSQL_VERSION}"
ACTUAL_SOURCE_PATH="${SRC_DIR}/${EXPECTED_SOURCE_SUBDIR}"

BUNDLED_BOOST_PARENT_DIR="${ACTUAL_SOURCE_PATH}/boost"
BUNDLED_BOOST_VERSION_DIR="${BUNDLED_BOOST_PARENT_DIR}/${EXPECTED_BOOST_DIR_NAME}"
BUNDLED_BOOST_VERSION_FILE="${BUNDLED_BOOST_VERSION_DIR}/boost/version.hpp"

echo "--- MySQL iOS Build Setup (Version: ${MYSQL_VERSION}) ---"
echo "Base Directory:       ${BASE_WORK_DIR}"
echo "Media (Archives):     ${MEDIA_DIR}"
echo "Source (Extracted):   ${SRC_DIR}"
echo "Build Parent Dir:     ${BUILD_PARENT_DIR}"
echo "CMake Work Subdir:    ${CMAKE_SUBDIR_NAME}"
echo "Full CMake Work Path: ${CMAKE_WORK_DIR}"
echo "Expecting Boost Dir:  ${BUNDLED_BOOST_VERSION_DIR}"

mkdir -p "${MEDIA_DIR}"
mkdir -p "${SRC_DIR}"
echo "Ensured media and source directories exist."

echo "Cleaning and creating CMake working directory: ${CMAKE_WORK_DIR}"
rm -rf "${CMAKE_WORK_DIR}"
mkdir -p "${CMAKE_WORK_DIR}"
echo "CMake working directory is ready."

if [ ! -f "${TARBALL_PATH}" ]; then
	echo "Downloading ${TARBALL_NAME} to ${MEDIA_DIR}..."
	if curl -L -o "${TARBALL_PATH}" "${MYSQL_URL}"; then
		echo "Download complete."
	else
		echo "ERROR: Failed to download ${TARBALL_NAME}."
		rm -f "${TARBALL_PATH}"
		exit 1
	fi
else
	echo "${TARBALL_NAME} already exists in ${MEDIA_DIR}. Skipping download."
fi

if [ ! -d "${ACTUAL_SOURCE_PATH}" ]; then
	echo "Extracting ${TARBALL_PATH} into ${SRC_DIR}..."
	if tar -xzf "${TARBALL_PATH}" -C "${SRC_DIR}"; then
		if [ -d "${ACTUAL_SOURCE_PATH}" ]; then
			echo "Extraction complete. Source code is in: ${ACTUAL_SOURCE_PATH}"
		else
			echo "ERROR: Extraction seemed successful, but the expected directory ${ACTUAL_SOURCE_PATH} was not found."
			exit 1
		fi
	else
		echo "ERROR: Failed to extract ${TARBALL_NAME}."
		echo "You may need to manually clean the ${SRC_DIR} directory."
		exit 1
	fi
else
	echo "Source directory ${ACTUAL_SOURCE_PATH} already exists. Skipping extraction."
fi

echo "Verifying bundled Boost installation..."
if [ ! -f "${BUNDLED_BOOST_VERSION_FILE}" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "ERROR: Expected Boost file NOT FOUND at: ${BUNDLED_BOOST_VERSION_FILE}"
    echo "       Check if the tarball extracted correctly and contains the Boost files."
    echo "       Expected Boost parent directory: ${BUNDLED_BOOST_PARENT_DIR}"
    echo "       Expected Boost version directory: ${BUNDLED_BOOST_VERSION_DIR}"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
else
    echo "Bundled Boost version file found successfully at ${BUNDLED_BOOST_VERSION_FILE}."
fi

SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)

C_COMPILER=$(xcrun --sdk iphoneos -f clang)
CXX_COMPILER=$(xcrun --sdk iphoneos -f clang++)

if [ -z "$SDK_PATH" ] || [ ! -d "$SDK_PATH" ]; then
  echo "Error: Could not find iOS SDK path."
  exit 1
fi
if [ -z "$C_COMPILER" ] || [ ! -x "$C_COMPILER" ]; then
  echo "Error: Could not find C compiler (clang)."
  exit 1
fi
if [ -z "$CXX_COMPILER" ] || [ ! -x "$CXX_COMPILER" ]; then
  echo "Error: Could not find C++ compiler (clang++)."
  exit 1
fi

echo "Using SDK Path: ${SDK_PATH}"
echo "Using C Compiler: ${C_COMPILER}"
echo "Using C++ Compiler: ${CXX_COMPILER}"

TARGET_ARCH="arm64"
MIN_IOS_VERSION="13.0"

export CFLAGS="-arch ${TARGET_ARCH} -isysroot ${SDK_PATH} -miphoneos-version-min=${MIN_IOS_VERSION}"
export CXXFLAGS="-arch ${TARGET_ARCH} -isysroot ${SDK_PATH} -miphoneos-version-min=${MIN_IOS_VERSION}"

echo "--- Setting up initial CMake configuration ---"
echo "Configuring inside: ${CMAKE_WORK_DIR}"
echo "Using source from:  ${ACTUAL_SOURCE_PATH}"

cd "${CMAKE_WORK_DIR}" || exit 1
echo "Changed directory to ${PWD}"

echo "Running initial CMake configuration (using Xcode generator and pointing to bundled Boost)..."

cmake -G Xcode \
	-DWITHOUT_SERVER=ON \
	-DBUILD_SHARED_LIBS=OFF \
	-DWITH_BOOST="${BUNDLED_BOOST_PARENT_DIR}" \
	-DOPENSSL_INCLUDE_DIR="/Users/michael/Desktop/Reports/Compressor/library/openssl/include" \
	-DOPENSSL_CRYPTO_LIBRARY="/Users/michael/Desktop/Reports/Compressor/library/openssl/lib/iOS-fat/libcrypto.a" \
	-DOPENSSL_SSL_LIBRARY="/Users/michael/Desktop/Reports/Compressor/library/openssl/lib/iOS-fat/libssl.a" \
	-DWITH_TEST_TRACE_PLUGIN=OFF \
	-DWITH_SASL=OFF \
	-DWITH_LDAP=OFF \
	-DWITH_UNIT_TESTS=OFF \
	"${ACTUAL_SOURCE_PATH}"

exit 0


#-------------------------------------------------------------------------------

	#-DPLATFORM="OS64COMBINED" \
	#-DCMAKE_TOOLCHAIN_FILE="/Users/michael/Downloads/ios-cmake-master/ios.toolchain.cmake" \
	#-DHAVE_CLOCK_GETTIME_EXITCODE=0 \
	#-DHAVE_CLOCK_GETTIME=1 \
	#-DHAVE_CLOCK_REALTIME_EXITCODE=0 \
	#-DHAVE_CLOCK_REALTIME=1 \
	#-DWITH_SYSTEM_LIBS=OFF \
	#-DWITH_READLINE=OFF \
	#-DWITH_LIBEDIT=OFF \
	#-DWITH_EDITLINE=OFF \
	#-DDISABLE_EDITLINE=ON \
	#-DENABLE_DTRACE=OFF \
	#-DWITH_AUTHENTICATION_SASL=OFF \
	#-DWITH_LDAP=OFF \
	#-DWITH_UNIT_TESTS=OFF \
	#-DENABLE_TESTING=OFF \
	#-DWITH_SSL="/Users/michael/Desktop/Reports/Compressor/library/openssl" \
	#"${ACTUAL_SOURCE_PATH}"


cmake -G Xcode \
	-DPLATFORM="OS64COMBINED" \
	-DCMAKE_TOOLCHAIN_FILE="/Users/michael/Downloads/ios-cmake-master/ios.toolchain.cmake" \
	-DWITHOUT_SERVER=ON \
	-DWITHOUT_DOCS=ON \
	-DWITHOUT_MYSQLD=ON \
	-DWITHOUT_MYSQL_CHECK=ON \
	-DBUILD_SHARED_LIBS=OFF \
	-DWITH_BOOST="${BUNDLED_BOOST_PARENT_DIR}" \
	-DOPENSSL_INCLUDE_DIR="/Users/michael/Desktop/Reports/Compressor/library/openssl/include" \
	-DOPENSSL_CRYPTO_LIBRARY="/Users/michael/Desktop/Reports/Compressor/library/openssl/lib/iOS-fat/libcrypto.a" \
	-DOPENSSL_SSL_LIBRARY="/Users/michael/Desktop/Reports/Compressor/library/openssl/lib/iOS-fat/libssl.a" \
	-DHAVE_CLOCK_GETTIME_EXITCODE=0 \
	-DHAVE_CLOCK_GETTIME=1 \
	-DHAVE_CLOCK_REALTIME_EXITCODE=0 \
	-DHAVE_CLOCK_REALTIME=1 \
	-DWITH_SYSTEM_LIBS=OFF \
	-DWITH_READLINE=OFF \
	-DWITH_LIBEDIT=OFF \
	-DWITH_EDITLINE=OFF \
	-DDISABLE_EDITLINE=ON \
	-DENABLE_DTRACE=OFF \
	-DWITH_AUTHENTICATION_SASL=OFF \
	-DWITH_LDAP=OFF \
	-DWITH_UNIT_TESTS=OFF \
	-DENABLE_TESTING=OFF \
	-DWITH_SSL="/Users/michael/Desktop/Reports/Compressor/library/openssl" \
	"${ACTUAL_SOURCE_PATH}"
	
#	-DCMAKE_SYSTEM_NAME=iOS \
#	-DCMAKE_SYSTEM_PROCESSOR=${TARGET_ARCH} \
#	-DCMAKE_OSX_ARCHITECTURES=${TARGET_ARCH} \
#	-DCMAKE_OSX_SYSROOT="${SDK_PATH}" \
#	-DCMAKE_OSX_DEPLOYMENT_TARGET="${MIN_IOS_VERSION}" \
#	-DCMAKE_C_COMPILER="${C_COMPILER}" \
#	-DCMAKE_CXX_COMPILER="${CXX_COMPILER}" \
#	-DCMAKE_C_FLAGS="${CFLAGS}" \
#	-DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
#	-DCMAKE_FIND_ROOT_PATH="${SDK_PATH}" \
#	-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
#	-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
#	-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
#	-DCMAKE_FIND_FRAMEWORK=ONLY \
#	-DCMAKE_FIND_APPBUNDLE=ONLY \
#	-DCMAKE_BUILD_TYPE=Release \


# --- CMake Post-Configuration ---
# This section is reached only if the cmake command above was successful.

echo "CMake configuration successful."
echo "Xcode project generated in: ${CMAKE_WORK_DIR}"
echo "You can check inside '${CMAKE_WORK_DIR}' for the '.xcodeproj' file."
echo "Remember: This project is configured for your macOS host, NOT for iOS."

echo ""
echo "--- Next Steps for iOS Build ---"
echo "1.  This script performed the download, extraction, and a BASIC Xcode project setup for your Mac inside '${CMAKE_WORK_DIR}'."
echo "2.  This directory '${CMAKE_WORK_DIR}' IS NOT suitable for iOS builds and will be cleaned on the next run."
echo "3.  To build for iOS, you must create SEPARATE, PERSISTENT build directories under '${BUILD_PARENT_DIR}' (or elsewhere), for example:"
echo "    - ${BUILD_PARENT_DIR}/build_ios_arm64"
echo "    - ${BUILD_PARENT_DIR}/build_sim_x86_64"
echo "    - ${BUILD_PARENT_DIR}/build_sim_arm64"
echo "4.  From within EACH separate iOS build directory, run 'cmake' again with the specific iOS options, *including* the WITH_BOOST flag:"
echo "    (Example for iOS device arm64)"
echo "    cd ${BUILD_PARENT_DIR}"
echo "    mkdir -p build_ios_arm64 && cd build_ios_arm64"
echo "    cmake \\"
echo "        -DCMAKE_SYSTEM_NAME=iOS \\"
echo "        -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \\"
echo "        -DCMAKE_OSX_SYSROOT=\$(xcrun --sdk iphoneos --show-sdk-path) \\"
echo "        -DCMAKE_OSX_ARCHITECTURES=arm64 \\"
echo "        -DCMAKE_INSTALL_PREFIX=${BUILD_PARENT_DIR}/install_ios_arm64 \\"
echo "        -DCMAKE_BUILD_TYPE=Release \\"
echo "        -DBUILD_SHARED_LIBS=OFF \\"
echo "        -DWITH_EDITLINE=OFF \\"
echo "        -DWITH_UNIT_TESTS=OFF \\"
echo "        -DWITH_BOOST=${BUNDLED_BOOST_PARENT_DIR} \\" # Essential Boost flag!
        # Add flags for OpenSSL if needed
echo "        -G \"Unix Makefiles\" \\"
echo "        ${ACTUAL_SOURCE_PATH}"
echo "    make install"
echo "5.  Repeat step 4 for other targets (sim x86_64, sim arm64) using different build directories and adjusted CMake flags (SDK, Arch, Install Prefix), always including -DWITH_BOOST."
echo "6.  Use 'lipo' to combine the simulator libraries from their respective install directories."
echo ""
echo "Script finished successfully."

# Go back to the starting directory (optional)
# cd - > /dev/null

exit 0


cmake -S"/Users/michael/Desktop/Reports/Compressor/build_temp/mysql-8.0.41" \
	-B"/Users/michael/Desktop/Reports/Compressor/build_temp/mysqlbuild" \
	-G Xcode \
	-DDOWNLOAD_BOOST=1 -DWITH_BOOST="/Users/michael/Desktop/Reports/Compressor/build_temp/boost" \
	-DCURSES_INCLUDE_PATH="/opt/homebrew/opt/ncurses/include" \
	-DCURSES_LIBRARY="/opt/homebrew/opt/ncurses/lib/libncurses.dylib" \
	-DOPENSSL_CRYPTO_LIBRARY="/Users/michael/Desktop/Reports/Compressor/library/openssl/framework/openssl-ios-armv7_armv7s_arm64_arm64e.a" \
	-DWITHOUT_SERVER=ON \
	-DWITH_UNIT_TESTS=OFF \
	-DBUILD_SHARED_LIBS=OFF \
	-DCMAKE_LIBEVENT_INCLUDE_DIRS="/opt/homebrew/opt/libevent/include" \
	-DCMAKE_LIBEVENT_LIBRARIES="/opt/homebrew/opt/libevent/lib/libevent.dylib"

	#-DOPENSSL_INCLUDE_DIR="/Users/michael/Desktop/Reports/Compressor/library/openssl/include" \
	#-DOPENSSL_SSL_LIBRARY="/Users/michael/Desktop/Reports/Compressor/library/openssl/framework/openssl-ios-armv7_armv7s_arm64_arm64e.a" \

#	-DCMAKE_OSX_SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.2.sdk" \
#	-DCMAKE_OSX_ARCHITECTURES="arm64" \
#	-DCMAKE_OSX_DEPLOYMENT_TARGET="14.0" \
 #	-DWITH_LIBEVENT=bundled
#-DIPHONEOS_DEPLOYMENT_TARGET="13.0"
	
#	-DFORCE_UNSUPPORTED_COMPILER=1 \
#	-DWITHOUT_SERVER=ON \
#	-DBUILD_SHARED_LIBS=OFF \
#	-DWITH_SSL=system \



