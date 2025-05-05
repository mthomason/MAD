#!/bin/bash

# Strict error handling and cleanup for robustness
set -eo pipefail
trap 'echo "Error at line $LINENO"; exit 1' ERR

# Configuration
SCRIPT_DIR="/Users/michael/Desktop/Reports/Compressor"
MEDIA_DIR="${SCRIPT_DIR}/media"
SRC_DIR="${SCRIPT_DIR}/src"
BUILD_DIR="${SCRIPT_DIR}/build/bzip2"
LIBRARY_DIR="${SCRIPT_DIR}/library/bzip2"
BZIP2_ARCHIVE="${MEDIA_DIR}/bzip2-1.0.8.tar.gz"
BZIP2_SOURCE_DIR="${SRC_DIR}/bzip2-1.0.8"

# Create required directories
mkdir -p "${SRC_DIR}" "${BUILD_DIR}" "${LIBRARY_DIR}"

# Verify and extract source
if [[ ! -d "${BZIP2_SOURCE_DIR}" ]]; then
	if [[ -f "${BZIP2_ARCHIVE}" ]]; then
		echo "Extracting bzip2 source..."
		tar -xzf "${BZIP2_ARCHIVE}" -C "${SRC_DIR}"
	else
		echo "ERROR: Missing bzip2 archive at ${BZIP2_ARCHIVE}"
		exit 1
	fi
fi

# Platform definitions (name,sdk,archs,min_version)
PLATFORMS=(
	"iOS,iphoneos,arm64 arm64e,13.0"
	"iOS-simulator,iphonesimulator,x86_64 arm64,13.0"
	"watchOS,watchos,arm64_32 armv7k,6.0"
	"watchOS-simulator,watchsimulator,arm64,6.0"
	"tvOS,appletvos,arm64,13.0"
	"tvOS-simulator,appletvsimulator,x86_64,13.0"
	"macOS,macosx,x86_64 arm64,10.15"
	"macCatalyst,macosx,x86_64 arm64,13.0"
)

build_for_platform() {
	local name=$1
	local sdk=$2
	local archs=($3)
	local min_version=$4
	
	echo "Building ${name}..."
	
	local sdk_path=$(xcrun --sdk "${sdk}" --show-sdk-path)
	local platform_build_dir="${BUILD_DIR}/${name}"
	local output_dir="${LIBRARY_DIR}/${name}"
	mkdir -p "${output_dir}"
	
	declare -a libraries
	
	for arch in "${archs[@]}"; do
		echo " Building ${arch}..."
		local arch_build_dir="${platform_build_dir}/${arch}"
		mkdir -p "${arch_build_dir}/source"
		
		# Copy fresh source for each architecture
		cp -R "${BZIP2_SOURCE_DIR}/"* "${arch_build_dir}/source/"
		
		pushd "${arch_build_dir}/source" > /dev/null
		
		# Platform-specific compiler settings
		local cflags="-O3 -DNDEBUG -arch ${arch} -isysroot ${sdk_path}"
		local ldflags="${cflags}"
		
		case "${name}" in
			iOS)          cflags+=" -miphoneos-version-min=${min_version}" ;;
			iOS-simulator) cflags+=" -miphonesimulator-version-min=${min_version}" ;;
			watchOS)       cflags+=" -mwatchos-version-min=${min_version}" ;;
			watchOS-simulator) cflags+=" -mwatchsimulator-version-min=${min_version}" ;;
			tvOS)          cflags+=" -mtvos-version-min=${min_version}" ;;
			tvOS-simulator) cflags+=" -mtvossimulator-version-min=${min_version}" ;;
			macOS)         cflags+=" -mmacosx-version-min=${min_version}" ;;
			macCatalyst)   cflags+=" -target ${arch}-apple-ios${min_version}-macabi" ;;
		esac

		# Find build tools
		local cc=$(xcrun --sdk "${sdk}" --find clang)
		local ar=$(xcrun --sdk "${sdk}" --find ar)
		local ranlib=$(xcrun --sdk "${sdk}" --find ranlib)
		
		# Build commands
		make clean > /dev/null 2>&1 || true
		make -j$(sysctl -n hw.ncpu) \
			CC="${cc}" \
			AR="${ar}" \
			RANLIB="${ranlib}" \
			CFLAGS="${cflags}" \
			LDFLAGS="${ldflags}" \
			> /dev/null
		
		# Install to temporary directory
		mkdir -p "${arch_build_dir}/install"
		make install PREFIX="${arch_build_dir}/install" > /dev/null
		
		# Verify and collect library
		local lib_path="${arch_build_dir}/install/lib/libbz2.a"
		if [[ -f "${lib_path}" ]]; then
			libraries+=("${lib_path}")
		else
			echo "ERROR: Failed to build ${arch}"
			exit 1
		fi
		
		popd > /dev/null
	done
	
	# Create universal binary
	echo "  Creating universal library..."
	lipo -create "${libraries[@]}" -output "${output_dir}/libbz2.a"
	lipo -info "${output_dir}/libbz2.a"
}

# Main build process
for platform in "${PLATFORMS[@]}"; do
	IFS=',' read -r name sdk archs min_version <<< "${platform}"
	build_for_platform "${name}" "${sdk}" "${archs}" "${min_version}"
done

echo "Build complete! Libraries in: ${LIBRARY_DIR}"
