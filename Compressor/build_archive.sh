#!/bin/bash

# Strict error handling and cleanup
set -eo pipefail
trap 'echo "Error at line $LINENO"; cleanup; exit 1' ERR

# Configuration
SCRIPT_DIR="/Users/michael/Desktop/Reports/Compressor"
MEDIA_DIR="${SCRIPT_DIR}/media"
SRC_DIR="${SCRIPT_DIR}/src"
BUILD_DIR="${SCRIPT_DIR}/build/libarchive"
LIBRARY_DIR="${SCRIPT_DIR}/library/libarchive"
LIBARCHIVE_ARCHIVE="${MEDIA_DIR}/libarchive-3.7.8.tar.gz"
LIBARCHIVE_SOURCE_DIR="${SRC_DIR}/libarchive-3.7.8"
BZIP2_LIBRARY_DIR="${SCRIPT_DIR}/library/bzip2"

# Cleanup function
cleanup() {
	echo "Cleaning up..."
	# Add any temporary file cleanup here if needed
}

# Verify Xcode tools
verify_xcode() {
	if ! xcrun --sdk iphoneos --find clang > /dev/null; then
		echo "ERROR: Xcode command line tools not found."
		exit 1
	fi
}

# Create required directories
mkdir -p "${SRC_DIR}" "${BUILD_DIR}" "${LIBRARY_DIR}"

# Verify and extract source
if [[ ! -d "${LIBARCHIVE_SOURCE_DIR}" ]]; then
	if [[ -f "${LIBARCHIVE_ARCHIVE}" ]]; then
		echo "Extracting libarchive source..."
		tar -xzf "${LIBARCHIVE_ARCHIVE}" -C "${SRC_DIR}"
	else
		echo "ERROR: Missing libarchive archive at ${LIBARCHIVE_ARCHIVE}"
		exit 1
	fi
fi

# Platform definitions (name,sdk,archs,min_version)
#	"watchOS,watchos,arm64_32 armv7k,6.0"
#	"watchOS-simulator,watchsimulator,arm64,6.0"
#	"tvOS,appletvos,arm64,13.0"
#	"tvOS-simulator,appletvsimulator,x86_64,13.0"

PLATFORMS=(
	"iOS,iphoneos,arm64 arm64e,13.0"
	"iOS-arm64e,iphoneos,arm64e,13.0"
	"iOS-simulator,iphonesimulator,x86_64 arm64,13.0"
	"macOS,macosx,x86_64 arm64,10.15"
)

build_for_platform() {
	local name=$1
	local sdk=$2
	local archs=$3
	local min_version=$4

	echo "Building ${name}..."

	local sdk_path=$(xcrun --sdk "${sdk}" --show-sdk-path)
	local platform_build_dir="${BUILD_DIR}/${name}"
	local output_dir="${LIBRARY_DIR}/${name}"

	# Clean previous build
	rm -rf "${platform_build_dir}"
	rm -rf "${output_dir}"
	mkdir -p "${output_dir}"/{include,lib}

	declare -a libraries

	for arch in ${archs}; do
		echo "  Building ${arch}..."
		local arch_build_dir="${platform_build_dir}/${arch}"
		mkdir -p "${arch_build_dir}"

		# Path to bzip2 for this platform
		local bzip2_include="${BZIP2_LIBRARY_DIR}/${name}/include"
		local bzip2_lib="${BZIP2_LIBRARY_DIR}/${name}/lib/libbz2.a"

		if [[ ! -f "${bzip2_lib}" ]]; then
			echo "ERROR: Missing bzip2 library at ${bzip2_lib}"
			exit 1
		fi

		# Configure CMAKE
		pushd "${arch_build_dir}" > /dev/null

		# Compiler settings
		local cc=$(xcrun --sdk "${sdk}" --find clang)
		local cflags="-arch ${arch} -isysroot ${sdk_path} -m${sdk}-version-min=${min_version}"
		local cxxflags="${cflags}"

		# Configure libarchive with CMake
		cmake "${LIBARCHIVE_SOURCE_DIR}" \
			-DCMAKE_SYSTEM_NAME=Darwin \
			-DCMAKE_OSX_SYSROOT="${sdk_path}" \
			-DCMAKE_OSX_ARCHITECTURES="${arch}" \
			-DCMAKE_OSX_DEPLOYMENT_TARGET="${min_version}" \
			-DCMAKE_C_COMPILER="${cc}" \
			-DCMAKE_CXX_COMPILER="$(xcrun --sdk "${sdk}" --find clang++)" \
			-DCMAKE_C_FLAGS="${cflags} -I${sdk_path}/usr/include/libxml2" \
			-DCMAKE_CXX_FLAGS="${cxxflags} -I${sdk_path}/usr/include/libxml2" \
			-DLIBXML2_INCLUDE_DIR="${sdk_path}/usr/include/libxml2" \
			-DLIBXML2_LIBRARIES="-lxml2" \
			-DENABLE_BZip2=ON \
			-DBZIP2_INCLUDE_DIR="${bzip2_include}" \
			-DBZIP2_LIBRARY="${bzip2_lib}" \
			-DENABLE_XML2=ON \
			-DENABLE_ZLIB=ON \
			-DZLIB_LIBRARY="-lz" \
			-DZLIB_INCLUDE_DIR="${sdk_path}/usr/include" \
			-DENABLE_LZMA=ON \
			-DLZMA_LIBRARY="-llzma" \
			-DLZMA_INCLUDE_DIR="${sdk_path}/usr/include" \
			-DENABLE_ZSTD=OFF \
			-DENABLE_OPENSSL=OFF \
			-DBUILD_SHARED_LIBS=OFF \
			-DCMAKE_BUILD_TYPE=Release \
			-DENABLE_TAR=ON \
			-DENABLE_CPIO=ON \
			-DENABLE_LZ4=OFF \
			-DENABLE_TEST=OFF

		# Build libarchive
		make -j$(sysctl -n hw.ncpu)

		# Path to the built static library
		local lib_path="${arch_build_dir}/libarchive/libarchive.a"
		if [[ -f "${lib_path}" ]]; then
			libraries+=("${lib_path}")
		else
			echo "ERROR: Failed to build libarchive for ${arch}"
			exit 1
		fi

		popd > /dev/null
	done

	# Create universal binary
	echo "  Creating universal library..."
	lipo -create "${libraries[@]}" -output "${output_dir}/lib/libarchive.a"
	lipo -info "${output_dir}/lib/libarchive.a"

	# Copy headers
	cp -R "${LIBARCHIVE_SOURCE_DIR}/libarchive/"*.h "${output_dir}/include/"
}

# Main execution
verify_xcode

for platform in "${PLATFORMS[@]}"; do
	IFS=',' read -r name sdk archs min_version <<< "${platform}"
	build_for_platform "${name}" "${sdk}" "${archs}" "${min_version}"
done

echo "Build complete! Libraries in: ${LIBRARY_DIR}"
