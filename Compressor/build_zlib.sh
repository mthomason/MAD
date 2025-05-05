#!/bin/bash
set -e

# Configuration
ZLIB_VERSION="1.3.1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/library/zlib"
BUILD_DIR="${SCRIPT_DIR}/build/zlib"
SOURCE_DIR="${SCRIPT_DIR}/source/zlib"

# Architectures to build (device + simulator)
ARCHS=(
	"armv7 iphoneos iphoneos"
	"armv7s iphoneos iphoneos"
	"arm64 iphoneos iphoneos"
	"x86_64 iphonesimulator iphonesimulator"
	"arm64 iphonesimulator iphonesimulator"
)

# Clean previous builds
rm -rf "${BUILD_DIR}" "${OUTPUT_DIR}" "${SOURCE_DIR}"
mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}" "${SOURCE_DIR}"

# Download zlib
curl -OL "https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
tar -xzf "zlib-${ZLIB_VERSION}.tar.gz" -C "${SOURCE_DIR}" --strip-components=1

# Build function
build_zlib() {
  local ARCH=$1
  local PLATFORM=$2
  local SDK=$3

  echo "Building zlib for ${ARCH} (${PLATFORM})..."

  # SDK paths
  export CC="$(xcrun --sdk ${SDK} --find clang) -arch ${ARCH}"
  export CFLAGS="-isysroot $(xcrun --sdk ${SDK} --show-sdk-path) -m${PLATFORM}-version-min=10.0"
  export LDFLAGS=""
  export AR=$(xcrun --sdk ${SDK} --find ar)
  export RANLIB=$(xcrun --sdk ${SDK} --find ranlib)

  # Build directory
  local ARCH_BUILD_DIR="${BUILD_DIR}/${PLATFORM}/${ARCH}"
  mkdir -p "${ARCH_BUILD_DIR}"
  cd "${SOURCE_DIR}"

  # Configure and build
  ./configure --prefix="${ARCH_BUILD_DIR}" --static
  make -j$(sysctl -n hw.ncpu)
  make install
  make clean
}

# Build for all architectures
for arch_info in "${ARCHS[@]}"; do
  build_zlib $arch_info
done

# Create universal libraries
mkdir -p "${OUTPUT_DIR}/lib"
lipo -create \
  "${BUILD_DIR}/iphoneos/armv7/lib/libz.a" \
  "${BUILD_DIR}/iphoneos/armv7s/lib/libz.a" \
  "${BUILD_DIR}/iphoneos/arm64/lib/libz.a" \
  -output "${OUTPUT_DIR}/lib/libz_ios_device.a"

lipo -create \
  "${BUILD_DIR}/iphonesimulator/x86_64/lib/libz.a" \
  "${BUILD_DIR}/iphonesimulator/arm64/lib/libz.a" \
  -output "${OUTPUT_DIR}/lib/libz_ios_simulator.a"

# Copy headers
cp -R "${BUILD_DIR}/iphoneos/arm64/include" "${OUTPUT_DIR}/"

echo "zlib build complete. Libraries in ${OUTPUT_DIR}"
