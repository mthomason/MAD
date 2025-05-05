#!/bin/bash
set -e

# Configuration
FREETDS_VERSION="1.4.26"
TDS_VERSION="7.4"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENSSL_BASE="${SCRIPT_DIR}/library/openssl"  # Absolute path
MIN_IOS_ARM64="12.0"
MIN_IOS_ARM32="10.0"
MIN_MACOS="10.13"
OUTPUT_DIR="${SCRIPT_DIR}/library/freetds"

# Clean previous builds
rm -rf "freetds-${FREETDS_VERSION}" build
curl -OL "https://www.freetds.org/files/stable/freetds-${FREETDS_VERSION}.tar.gz"
tar -xzf "freetds-${FREETDS_VERSION}.tar.gz"
cd "freetds-${FREETDS_VERSION}"

# Debugging function
debug_paths() {
    local PLATFORM=$1
    local ARCH=$2
    local OPENSSL_LIB_DIR=$3

    echo "Debugging paths for ${PLATFORM} ${ARCH}:"
    echo "  - OPENSSL_BASE: ${OPENSSL_BASE}"
    echo "  - OPENSSL_LIB_DIR: ${OPENSSL_LIB_DIR}"
    echo "  - Checking for OpenSSL libraries in ${OPENSSL_LIB_DIR}:"
    ls -l "${OPENSSL_LIB_DIR}" || echo "  -> OpenSSL library directory not found!"
    echo "  - Checking for OpenSSL headers in ${OPENSSL_BASE}/include:"
    ls -l "${OPENSSL_BASE}/include/openssl" || echo "  -> OpenSSL headers directory not found!"
}

# Build function
build_platform() {
    local PLATFORM=$1
    local ARCH=$2
    local SDK=$3
    local HOST=$4
    local OPENSSL_LIB_DIR=$5
    local MIN_VERSION=$6

    echo "Building ${PLATFORM} ${ARCH}..."

    # Debug paths
    debug_paths "${PLATFORM}" "${ARCH}" "${OPENSSL_LIB_DIR}"

    export CC="$(xcrun --sdk ${SDK} --find clang) -arch ${ARCH}"
    export CFLAGS="-isysroot $(xcrun --sdk ${SDK} --show-sdk-path) -m${7}-version-min=${MIN_VERSION} -I${OPENSSL_BASE}/include"
    export LDFLAGS="-L${OPENSSL_LIB_DIR}"
    export CPPFLAGS="-I${OPENSSL_BASE}/include"

    # Configure with proper prefix
    ./configure \
        --host=${HOST} \
        --enable-msdblib \
        --disable-apps \
        --disable-server \
        --disable-pool \
        --disable-odbc \
        --with-tdsver=${TDS_VERSION} \
        --prefix="/usr/local"
        #\
        #--with-openssl="${OPENSSL_BASE}"

    # Clean, build, and install
    make clean
    make -j$(sysctl -n hw.ncpu)
    make install DESTDIR="${PWD}/build/${PLATFORM}/${ARCH}"
}

# iOS Architectures
build_platform "iphoneos" "armv7" "iphoneos" "armv7-apple-darwin" "${OPENSSL_BASE}/lib/iOS-fat" $MIN_IOS_ARM32 "iphoneos"
build_platform "iphoneos" "armv7s" "iphoneos" "armv7s-apple-darwin" "${OPENSSL_BASE}/lib/iOS-fat" $MIN_IOS_ARM32 "iphoneos"
build_platform "iphoneos" "arm64" "iphoneos" "aarch64-apple-darwin" "${OPENSSL_BASE}/lib/iOS-fat" $MIN_IOS_ARM64 "iphoneos"
build_platform "iphoneos" "arm64e" "iphoneos" "aarch64-apple-darwin" "${OPENSSL_BASE}/lib/iOS-fat" $MIN_IOS_ARM64 "iphoneos"

# iOS Simulator Architectures
build_platform "iphonesimulator" "i386" "iphonesimulator" "i386-apple-darwin" "${OPENSSL_BASE}/lib/iOS-simulator" $MIN_IOS_ARM32 "ios-simulator"
build_platform "iphonesimulator" "x86_64" "iphonesimulator" "x86_64-apple-darwin" "${OPENSSL_BASE}/lib/iOS-simulator" $MIN_IOS_ARM64 "ios-simulator"
build_platform "iphonesimulator" "arm64" "iphonesimulator" "aarch64-apple-darwin" "${OPENSSL_BASE}/lib/iOS-simulator" $MIN_IOS_ARM64 "ios-simulator"

# macOS Architectures
build_platform "macosx" "x86_64" "macosx" "x86_64-apple-darwin" "${OPENSSL_BASE}/lib/MacOS" $MIN_MACOS "macosx"
build_platform "macosx" "arm64" "macosx" "aarch64-apple-darwin" "${OPENSSL_BASE}/lib/MacOS" $MIN_MACOS "macosx"

# Ensure output directories exist
mkdir -p "${OUTPUT_DIR}/lib/iOS-fat"
mkdir -p "${OUTPUT_DIR}/lib/iOS-simulator"
mkdir -p "${OUTPUT_DIR}/lib/MacOS"

# Create universal libraries
lipo -create \
    build/iphoneos/armv7/usr/local/lib/libsybdb.a \
    build/iphoneos/armv7s/usr/local/lib/libsybdb.a \
    build/iphoneos/arm64/usr/local/lib/libsybdb.a \
    build/iphoneos/arm64e/usr/local/lib/libsybdb.a \
    -output "${OUTPUT_DIR}/lib/iOS-fat/libsybdb.a"

lipo -create \
    build/iphoneos/armv7/usr/local/lib/libct.a \
    build/iphoneos/armv7s/usr/local/lib/libct.a \
    build/iphoneos/arm64/usr/local/lib/libct.a \
    build/iphoneos/arm64e/usr/local/lib/libct.a \
    -output "${OUTPUT_DIR}/lib/iOS-fat/libct.a"


lipo -create \
    build/iphonesimulator/i386/usr/local/lib/libsybdb.a \
    build/iphonesimulator/x86_64/usr/local/lib/libsybdb.a \
    build/iphonesimulator/arm64/usr/local/lib/libsybdb.a \
    -output "${OUTPUT_DIR}/lib/iOS-simulator/libsybdb.a"

lipo -create \
    build/iphonesimulator/i386/usr/local/lib/libct.a \
    build/iphonesimulator/x86_64/usr/local/lib/libct.a \
    build/iphonesimulator/arm64/usr/local/lib/libct.a \
    -output "${OUTPUT_DIR}/lib/iOS-simulator/libct.a"


lipo -create \
    build/macosx/x86_64/usr/local/lib/libsybdb.a \
    build/macosx/arm64/usr/local/lib/libsybdb.a \
    -output "${OUTPUT_DIR}/lib/MacOS/libsybdb.a"

lipo -create \
    build/macosx/x86_64/usr/local/lib/libct.a \
    build/macosx/arm64/usr/local/lib/libct.a \
    -output "${OUTPUT_DIR}/lib/MacOS/libct.a"

lipo -create \
    build/iphoneos/armv7/usr/local/lib/libsybdb.a \
    build/iphoneos/armv7s/usr/local/lib/libsybdb.a \
    build/iphoneos/arm64/usr/local/lib/libsybdb.a \
    build/iphoneos/arm64e/usr/local/lib/libsybdb.a \
    build/iphonesimulator/i386/usr/local/lib/libsybdb.a \
    build/iphonesimulator/x86_64/usr/local/lib/libsybdb.a \
    -output "${OUTPUT_DIR}/lib/libsybdb.a"

lipo -create \
    build/iphoneos/armv7/usr/local/lib/libct.a \
    build/iphoneos/armv7s/usr/local/lib/libct.a \
    build/iphoneos/arm64/usr/local/lib/libct.a \
    build/iphoneos/arm64e/usr/local/lib/libct.a \
    build/iphonesimulator/i386/usr/local/lib/libct.a \
    build/iphonesimulator/x86_64/usr/local/lib/libct.a \
    -output "${OUTPUT_DIR}/lib/libct.a"

# Copy headers
mkdir -p "${OUTPUT_DIR}/include"
cp -R build/iphoneos/arm64/usr/local/include/* "${OUTPUT_DIR}/include/"

echo "Build complete. Libraries in ${OUTPUT_DIR}"
