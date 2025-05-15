#!/bin/bash

# Strict error handling and cleanup
set -eo pipefail
trap 'echo "Error at line $LINENO"; cleanup; exit 1' ERR

# Configuration
BUILD_MACHINE=`uname -m`
SCRIPT_DIR="/Users/michael/Desktop/Reports/Compressor"
MEDIA_DIR="${SCRIPT_DIR}/media"
SRC_DIR="${SCRIPT_DIR}/src"
BUILD_DIR="${SCRIPT_DIR}/build/openssl"
LIBRARY_DIR="${SCRIPT_DIR}/library/openssl"
OPENSSL_VERSION="3.4.1"
OPENSSL_ARCHIVE="${MEDIA_DIR}/openssl-${OPENSSL_VERSION}.tar.gz"
OPENSSL_SOURCE_DIR="${SRC_DIR}/openssl-${OPENSSL_VERSION}"

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
mkdir -p "${MEDIA_DIR}" "${SRC_DIR}" "${BUILD_DIR}" "${LIBRARY_DIR}"

# Download and extract source if needed
if [[ ! -d "${OPENSSL_SOURCE_DIR}" ]]; then
    if [[ ! -f "${OPENSSL_ARCHIVE}" ]]; then
        echo "Downloading OpenSSL ${OPENSSL_VERSION}..."
        curl -L https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -o "${OPENSSL_ARCHIVE}"
    fi
    echo "Extracting OpenSSL source..."
    tar -xzf "${OPENSSL_ARCHIVE}" -C "${SRC_DIR}"
fi

# Platform definitions (name,sdk,archs,min_version,target)
PLATFORMS=(
    # iOS
    #"iOS,iphoneos,arm64,12.0,ios64-cross"
    #"iOS-arm64e,iphoneos,arm64e,12.0,ios64-cross"
    
    # iOS Simulator
    #"iOS-simulator,iphonesimulator,x86_64,12.0,iossimulator-x86_64-xcrun"
    "iOS-simulator-arm64,iphonesimulator,arm64,12.0,iossimulator-arm64-xcrun"
    
    # macOS
    #"macOS,macosx,x86_64,11.0,darwin64-x86_64-cc"
    #"macOS-arm64,macosx,arm64,11.0,darwin64-arm64-cc"
    
    # Mac Catalyst
    #"macCatalyst,macosx,x86_64,13.0,mac-catalyst-x86_64"
    #"macCatalyst-arm64,macosx,arm64,13.0,mac-catalyst-arm64"
    
    # watchOS
    #"watchOS-arm64_32,watchos,arm64_32,8.5,watchos-cross-arm64_32"
    #"watchOS-armv7k,watchos,armv7k,8.5,watchos-cross-armv7k"
    
    # watchOS Simulator
    #"watchOS-simulator,watchsimulator,arm64,8.5,watchos-sim-cross-arm64"
    
    # tvOS
    #"tvOS,appletvos,arm64,13.0,tvos-cross-arm64"
    
    # tvOS Simulator
    #"tvOS-simulator,appletvsimulator,x86_64,13.0,tvos-sim-cross-x86_64"
)

build_for_platform() {
    local name=$1
    local sdk=$2
    local archs=$3
    local min_version=$4
    local target=$5

    echo "Building ${name}..."

    local sdk_path=$(xcrun --sdk "${sdk}" --show-sdk-path)
    local platform_build_dir="${BUILD_DIR}/${name}"
    local output_dir="${LIBRARY_DIR}/${name}"
    local output_lib_dir="${output_dir}/lib"
    local output_include_dir="${output_dir}/include"

    # Clean previous build
    rm -rf "${platform_build_dir}" "${output_dir}"
    mkdir -p "${output_dir}"

    declare -a crypto_paths
    declare -a ssl_paths
    declare -a pkgconfig_paths

    for arch in ${archs}; do
        echo "  Building ${arch}..."
        local arch_build_dir="${platform_build_dir}/${arch}"
        mkdir -p "${arch_build_dir}"

        pushd "${arch_build_dir}" > /dev/null

        #local TARGET=""
        #local RUNTARGET=""
		

        # Determine platform name for cross-compilation
        local platform_version="$(xcrun -sdk iphoneos --show-sdk-version)"
        local platform_name="iPhoneOS"
        if [[ "${sdk}" == "iphonesimulator" ]]; then
            platform_name="iPhoneSimulator"
            platform_version="$(xcrun -sdk iphonesimulator --show-sdk-version)"
            
            #TARGET="darwin-i386-cc"
            #RUNTARGET=""
            #if [[ $ARCH != "i386" ]]; then
            #    TARGET="darwin64-${ARCH}-cc"
            #    RUNTARGET="-target ${ARCH}-apple-ios${IOS_MIN_SDK_VERSION}-simulator"
            #fi
            
        elif [[ "${sdk}" == "watchos" ]]; then
            platform_name="WatchOS"
            platform_version="$(xcrun -sdk watchos --show-sdk-version)"
        elif [[ "${sdk}" == "watchsimulator" ]]; then
            platform_name="WatchSimulator"
            platform_version="$(xcrun -sdk watchos --show-sdk-version)"
        elif [[ "${sdk}" == "appletvos" ]]; then
            platform_name="AppleTVOS"
            platform_version="$(xcrun -sdk appletvos --show-sdk-version)"
        elif [[ "${sdk}" == "appletvsimulator" ]]; then
            platform_name="AppleTVSimulator"
            platform_version="$(xcrun -sdk appletvos --show-sdk-version)"
        fi

        echo "  Building platform ${platform_name}${platform_version}.sdk..."
        # Set cross-compilation environment
        #export CROSS_COMPILE="$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/bin"
        export CROSS_TOP="$(xcode-select -p)/Platforms/${platform_name}.platform/Developer"
        export CROSS_SDK="${platform_name}${platform_version}.sdk"
        export PATH="${CROSS_TOP}/../usr/bin:${PATH}"

        # Compiler settings - use the full path to clang
        local cc="$(xcrun --sdk "${sdk}" --find clang)"
        local cflags="-arch ${arch} -isysroot ${sdk_path} -O3"
        local ldflags="${cflags}"

        # Special handling for arm64e
        if [[ "${arch}" == "arm64e" ]]; then
            cflags+=" -arch arm64e"
        fi

        # Minimum OS version flags
        case "${name}" in
            iOS*)              cflags+=" -miphoneos-version-min=${min_version}" ;;
            iOS-simulator*)
                cflags+=" -miphonesimulator-version-min=${min_version}"
                # Critical fix: Add explicit simulator target flag
                cflags+=" -target ${arch}-apple-ios${min_version}-simulator"
                ;;
            macOS*)            cflags+=" -mmacosx-version-min=${min_version}" ;;
            macCatalyst*)      cflags+=" -target ${arch}-apple-ios${min_version}-macabi" ;;
            watchOS*)          cflags+=" -mwatchos-version-min=${min_version}" ;;
            watchOS-simulator*) cflags+=" -mwatchsimulator-version-min=${min_version}" ;;
            tvOS*)            cflags+=" -mtvos-version-min=${min_version}" ;;
            tvOS-simulator*)  cflags+=" -mtvsimulator-version-min=${min_version}" ;;
        esac

        # Configure OpenSSL with no-async to prevent problematic symbols
        echo "Configuring for ${target} (${arch})..."
        "${OPENSSL_SOURCE_DIR}/Configure" \
            ${target} \
            no-shared \
            no-asm \
            no-deprecated \
            no-async \
            -arch ${arch} \
            --prefix="${arch_build_dir}/install" \
            --openssldir="${arch_build_dir}/install" \
            CC="${cc}" \
            CFLAGS="${cflags}" \
            LDFLAGS="${ldflags}"

        # Build and install
        echo "Building (logs in ${arch_build_dir}/make.log)..."
        if ! make -j$(sysctl -n hw.ncpu) > "${arch_build_dir}/make.log" 2>&1; then
            echo "Build failed. Output:"
            cat "${arch_build_dir}/make.log"
            exit 1
        fi

        echo "Installing (logs in ${arch_build_dir}/install.log)..."
        if ! make install_sw > "${arch_build_dir}/install.log" 2>&1; then
            echo "Install failed. Output:"
            cat "${arch_build_dir}/install.log"
            exit 1
        fi

        # Verify and collect libraries
        local crypto_path="${arch_build_dir}/install/lib/libcrypto.a"
        local ssl_path="${arch_build_dir}/install/lib/libssl.a"
        local pkgconfig_path="${arch_build_dir}/install/lib/pkgconfig"
        if [[ -f "${crypto_path}" && -f "${ssl_path}" ]]; then
            crypto_paths+=("${crypto_path}")
            ssl_paths+=("${ssl_path}")
            pkgconfig_path+=("${pkgconfig_path}")
        else
            echo "ERROR: Failed to build ${arch} for ${name}"
            exit 1
        fi

        popd > /dev/null
    done

    # Create universal libraries if we have multiple architectures
    if [ ${#crypto_paths[@]} -gt 1 ]; then
        echo " Creating universal libraries for ${name}..."
        mkdir -p "${output_lib_dir}"
        lipo -create "${crypto_paths[@]}" -output "${output_lib_dir}/libcrypto.a"
        lipo -create "${ssl_paths[@]}" -output "${output_lib_dir}/libssl.a"
    else
        echo " Copying single-architecture libraries for ${name}..."
        mkdir -p "${output_lib_dir}"
        cp "${crypto_paths[0]}" "${output_lib_dir}/libcrypto.a"
        cp "${ssl_paths[0]}" "${output_lib_dir}/libssl.a"
        cp -R "${pkgconfig_path[0]}" "${output_lib_dir}"
    fi
    
    lipo -info "${output_lib_dir}/libcrypto.a"
    lipo -info "${output_lib_dir}/libssl.a"
    
    # Copy headers (same for all architectures)
    mkdir -p "${output_include_dir}"
    cp -R "${platform_build_dir}/${arch}/install/include/"* "${output_include_dir}/" || true
}

# Main execution
verify_xcode

for platform in "${PLATFORMS[@]}"; do
    IFS=',' read -r name sdk archs min_version target <<< "${platform}"
    build_for_platform "${name}" "${sdk}" "${archs}" "${min_version}" "${target}"
done

# Create additional fat libraries combining platforms where needed
#echo "Creating combined iOS libraries..."
#mkdir -p "${LIBRARY_DIR}/iOS-fat"
#lipo -create \
#    "${LIBRARY_DIR}/iOS/libcrypto.a" \
#    "${LIBRARY_DIR}/iOS-arm64e/libcrypto.a" \
#    -output "${LIBRARY_DIR}/iOS-fat/libcrypto.a"
#lipo -create \
#    "${LIBRARY_DIR}/iOS/libssl.a" \
#    "${LIBRARY_DIR}/iOS-arm64e/libssl.a" \
#    -output "${LIBRARY_DIR}/iOS-fat/libssl.a"

echo "Creating combined iOS Simulator libraries..."
mkdir -p "${LIBRARY_DIR}/iOS-simulator-fat/lib"
lipo -create \
    "${LIBRARY_DIR}/iOS-simulator/lib/libcrypto.a" \
    "${LIBRARY_DIR}/iOS-simulator-arm64/lib/libcrypto.a" \
    -output "${LIBRARY_DIR}/iOS-simulator-fat/lib/libcrypto.a"
lipo -create \
    "${LIBRARY_DIR}/iOS-simulator/lib/libssl.a" \
    "${LIBRARY_DIR}/iOS-simulator-arm64/lib/libssl.a" \
    -output "${LIBRARY_DIR}/iOS-simulator-fat/lib/libssl.a"

echo "Creating combined macOS libraries..."
mkdir -p "${LIBRARY_DIR}/macOS-fat/lib"
lipo -create \
    "${LIBRARY_DIR}/macOS/lib/libcrypto.a" \
    "${LIBRARY_DIR}/macOS-arm64/lib/libcrypto.a" \
    -output "${LIBRARY_DIR}/macOS-fat/lib/libcrypto.a"
lipo -create \
    "${LIBRARY_DIR}/macOS/lib/libssl.a" \
    "${LIBRARY_DIR}/macOS-arm64/lib/libssl.a" \
    -output "${LIBRARY_DIR}/macOS-fat/lib/libssl.a"

#echo "Creating combined Mac Catalyst libraries..."
#mkdir -p "${LIBRARY_DIR}/macCatalyst-fat"
#lipo -create \
#    "${LIBRARY_DIR}/macCatalyst/libcrypto.a" \
#    "${LIBRARY_DIR}/macCatalyst-arm64/libcrypto.a" \
#    -output "${LIBRARY_DIR}/macCatalyst-fat/libcrypto.a"
#lipo -create \
#    "${LIBRARY_DIR}/macCatalyst/libssl.a" \
#    "${LIBRARY_DIR}/macCatalyst-arm64/libssl.a" \
#    -output "${LIBRARY_DIR}/macCatalyst-fat/libssl.a"

echo "Build complete! Libraries in: ${LIBRARY_DIR}"
