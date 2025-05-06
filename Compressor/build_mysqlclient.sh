#!/bin/bash

#
# Use this script to create the Xcode project that you can modify to create
#	libmysqlclient.
# The Xcode project must be modified.  Cmake can only make the project for
#	MacOS.
# The problem with cross compiling `libmysqlcient` for iOS is that building
#	this lib requires building a lot of static programs for MacOS first.  That
#	is `GenError` must first be built for MacOS, and then it can't be
#	a target for `clientlib` on iOS.  To get this to build for iOS, you
#	must basically build Unix from scratch, and it's just a utility so you
#	need to run it on MacOS while you are building `clientlib` for iOS.
#	`uca9dump` is another program that needs this.  These programs will need
#	to link with OpenSSL and other libs on MacOS when they build.  The prograrm
#	`strings` needs to be built for both MacOS, and iOS, and it may need to
#	link to other libs while need to be built for both MacOS and iOS.
# This is a pain to do.  I used the project at the following URL to help get
#	me started: [link](https://github.com/nanzhong/mysql-ios).
# When I had done this before, I think I used the `GenError` from an install
#	of MySQL, but I don't know if that's best practice, or if that's even still
#	possable.
#

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

