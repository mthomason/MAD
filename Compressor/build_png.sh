#!/bin/bash
set -e

# Configuration
readonly libpng_version="1.6.47"
readonly path_base="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly path_library="${path_base}/library/libpng"
readonly path_build="${path_base}/build/libpng"
readonly path_source="${path_base}/source/libpng"
readonly zlib_dir="${path_base}/library/zlib"

# Minimum iOS versions
readonly MIN_IOS_ARM32="10.0"
readonly MIN_IOS_ARM64="12.0"
readonly MIN_MACOS="10.13"

# Clean previous builds
rm -rf "${path_build}" "${path_library}" "${path_source}"
mkdir -p "${path_build}" "${path_library}" "${path_source}"

# Download libpng
readonly archive_name="libpng-${libpng_version}"
readonly archive_url="https://download.sourceforge.net/libpng/${archive_name}.tar.gz"
readonly archive_path="${path_base}/${archive_name}.tar.gz"

echo "Downloading libpng..."
curl -OL "${archive_url}"

# Extract libpng
echo "Extracting libpng..."
if [[ -f "${archive_path}" ]]; then
	tar -xzf "${archive_path}" -C "${path_source}" --strip-components=1
else
	echo "Error: Archive not found at ${archive_path}"
	exit 1
fi

# Verify extraction
if [[ ! -f "${path_source}/configure" ]]; then
	echo "Error: configure script not found in ${path_source}. Extraction may have failed."
	exit 1
fi

# Build function
build_platform() {
	local PLATFORM=$1
	local ARCH=$2
	local SDK=$3
	local HOST=$4
	local MIN_VERSION=$5

	echo "Building ${PLATFORM} ${ARCH}..."

	# SDK paths
	local sdk_path="$(xcrun --sdk ${SDK} --show-sdk-path)"
	local clang="$(xcrun --sdk ${SDK} --find clang)"

	# Use system libz.dylib if available
	local zlib_include="-I\"${zlib_dir}/include\""
	local zlib_lib="-L\"${zlib_dir}/lib\""

	# Check if system libz.dylib is compatible
	#if [[ "${ARCH}" == "armv7" || "${ARCH}" == "armv7s" ]]; then
	#	echo "System libz.dylib may not be compatible with ${ARCH}. Building zlib from source..."
	#	local zlib_arch_path="${path_base}/build/zlib/${PLATFORM}/${ARCH}"
	#	zlib_include="-I${zlib_arch_path}/include"
	#	zlib_lib="-L${zlib_arch_path}/lib"
	#fi

#	export CC="${clang} -arch ${ARCH}"
#	export LDFLAGS="${zlib_lib}"
#	export CFLAGS="-isysroot ${sdk_path} -m${PLATFORM}-version-min=${MIN_VERSION} -I${sdk_path}/usr/include ${zlib_include}"
#	export CPPFLAGS="-I${sdk_path}/usr/include ${zlib_include}"

	export CC="${clang} -arch ${ARCH}"
	export LDFLAGS=""  # Removed custom zlib lib
	export CFLAGS="-isysroot ${sdk_path} -m${PLATFORM}-version-min=${MIN_VERSION}"
	export CPPFLAGS="-I${sdk_path}/usr/include"

	# Create output directories
	local build_dir="${path_build}/${PLATFORM}/${ARCH}"
	mkdir -p "${build_dir}"

	# Configure
	cd "${path_source}"
	./configure \
		--host=${HOST} \
		--prefix="${build_dir}" \
		--enable-shared=no \
		--enable-static=yes \
		--disable-dependency-tracking

	# Clean, build, and install
	make clean
	make -j$(sysctl -n hw.ncpu)
	make install
	make distclean
}

# iOS Architectures
#build_platform "iphoneos" "armv7" "iphoneos" "armv7-apple-darwin" $MIN_IOS_ARM32
#build_platform "iphoneos" "armv7s" "iphoneos" "armv7s-apple-darwin" $MIN_IOS_ARM32
build_platform "iphoneos" "arm64" "iphoneos" "aarch64-apple-darwin" $MIN_IOS_ARM64
build_platform "iphoneos" "arm64e" "iphoneos" "aarch64-apple-darwin" $MIN_IOS_ARM64

# iOS Simulator Architectures
#build_platform "iphonesimulator" "i386" "iphonesimulator" "i386-apple-darwin" $MIN_IOS_ARM32
build_platform "iphonesimulator" "x86_64" "iphonesimulator" "x86_64-apple-darwin" $MIN_IOS_ARM64
build_platform "iphonesimulator" "arm64" "iphonesimulator" "aarch64-apple-darwin" $MIN_IOS_ARM64

# macOS Architectures
build_platform "macosx" "x86_64" "macosx" "x86_64-apple-darwin" $MIN_MACOS
build_platform "macosx" "arm64" "macosx" "aarch64-apple-darwin" $MIN_MACOS

# Create universal libraries
lipo -create \
	"${path_build}/iphoneos/arm64/lib/libpng.a" \
	"${path_build}/iphoneos/arm64e/lib/libpng.a" \
	-output "${path_library}/libpng_device.a"

#	"${path_build}/iphoneos/armv7/lib/libpng.a" \
#	"${path_build}/iphoneos/armv7s/lib/libpng.a" \

lipo -create \
	"${path_build}/iphonesimulator/x86_64/lib/libpng.a" \
	"${path_build}/iphonesimulator/arm64/lib/libpng.a" \
	-output "${path_library}/libpng_simulator.a"

#	"${path_build}/iphonesimulator/i386/lib/libpng.a" \

# Replace the existing lipo commands with:
lipo -create \
	"${path_build}/iphoneos/arm64/lib/libpng.a" \
	"${path_build}/iphoneos/arm64e/lib/libpng.a" \
	"${path_build}/iphonesimulator/x86_64/lib/libpng.a" \
	-output "${path_library}/libpng.a"  # Standard name

	#"${path_build}/iphonesimulator/arm64/lib/libpng.a" \
	#"${path_build}/iphoneos/armv7/lib/libpng.a" \
	#"${path_build}/iphoneos/armv7s/lib/libpng.a" \
	#"${path_build}/iphonesimulator/i386/lib/libpng.a" \


echo "Build complete. Libraries:"
echo "- Device: ${path_library}/libpng_device.a"
echo "- Simulator: ${path_library}/libpng_simulator.a"
