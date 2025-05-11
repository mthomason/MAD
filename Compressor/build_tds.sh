#!/bin/bash
set -eo pipefail

# Configuration
FREETDS_VERSION="1.4.26"
TDS_VERSION="7.4"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEDIA_DIR="${SCRIPT_DIR}/media"
SRC_DIR="${SCRIPT_DIR}/src"
BUILD_DIR="${SCRIPT_DIR}/build/freetds"
LIBRARY_DIR="${SCRIPT_DIR}/library/freetds"
OPENSSL_BASE="${SCRIPT_DIR}/library/openssl"
MIN_IOS_VERSION="12.0"
MIN_MACOS_VERSION="11.5"

# Debug function
debug() {
    echo "DEBUG: $@" >&2
}

# Cleanup function
cleanup() {
    echo "Cleaning up build directories..."
    rm -rf "${BUILD_DIR}"
}

# Verify Xcode tools
verify_xcode() {
    if ! xcrun --sdk iphoneos --find clang > /dev/null; then
        echo "ERROR: Xcode command line tools not found."
        exit 1
    fi
}

# Verify OpenSSL exists for platform
verify_openssl() {
    local openssl_path=$1
    local platform=$2
    
    if [[ ! -d "${openssl_path}" ]]; then
        echo "ERROR: Missing OpenSSL for ${platform} at ${openssl_path}"
        exit 1
    fi
    
    if [[ ! -f "${openssl_path}/lib/libssl.a" ]]; then
        echo "ERROR: Missing OpenSSL libraries for ${platform}"
        exit 1
    fi
}

# Update config.guess and config.sub to latest versions
update_autoconf_files() {
    local src_dir="${SRC_DIR}/freetds-${FREETDS_VERSION}"
    echo "Updating autoconf config files..."
    
    if ! curl -fsSL -o "${src_dir}/config.guess" "https://git.savannah.gnu.org/cgit/config.git/plain/config.guess"; then
        echo "ERROR: Failed to download config.guess"
        exit 1
    fi
    
    if ! curl -fsSL -o "${src_dir}/config.sub" "https://git.savannah.gnu.org/cgit/config.git/plain/config.sub"; then
        echo "ERROR: Failed to download config.sub"
        exit 1
    fi
    
    chmod +x "${src_dir}/config.guess" "${src_dir}/config.sub"
}

# Create required directories
mkdir -p "${MEDIA_DIR}" "${SRC_DIR}" "${BUILD_DIR}" "${LIBRARY_DIR}"

# Download and extract source if needed
if [[ ! -d "${SRC_DIR}/freetds-${FREETDS_VERSION}" ]]; then
    if [[ ! -f "${MEDIA_DIR}/freetds-${FREETDS_VERSION}.tar.gz" ]]; then
        echo "Downloading FreeTDS ${FREETDS_VERSION}..."
        if ! curl -L "https://www.freetds.org/files/stable/freetds-${FREETDS_VERSION}.tar.gz" -o "${MEDIA_DIR}/freetds-${FREETDS_VERSION}.tar.gz"; then
            echo "ERROR: Failed to download FreeTDS"
            exit 1
        fi
    fi
    
    echo "Extracting FreeTDS source..."
    if ! tar -xzf "${MEDIA_DIR}/freetds-${FREETDS_VERSION}.tar.gz" -C "${SRC_DIR}"; then
        echo "ERROR: Failed to extract FreeTDS"
        exit 1
    fi
    
    update_autoconf_files
fi

# Platform definitions (name,sdk,archs,min_version)
PLATFORMS=(
    # iOS
    "iOS,iphoneos,arm64,${MIN_IOS_VERSION}"
    "iOS-arm64e,iphoneos,arm64e,${MIN_IOS_VERSION}"
    
    # iOS Simulator
    "iOS-simulator,iphonesimulator,x86_64,${MIN_IOS_VERSION}"
    "iOS-simulator-arm64,iphonesimulator,arm64,${MIN_IOS_VERSION}"

    # macOS
    "macOS,macosx,x86_64,${MIN_MACOS_VERSION}"
    "macOS-arm64,macosx,arm64,${MIN_MACOS_VERSION}"
)


build_for_platform() {
    local name=$1
    local sdk=$2
    local arch=$3
    local min_version=$4

    echo "Building ${name} ${arch}..."
    debug "Platform details: name=${name}, sdk=${sdk}, arch=${arch}, min_version=${min_version}"

    local sdk_path=$(xcrun --sdk "${sdk}" --show-sdk-path)
    debug "SDK path: ${sdk_path}"
    
    local platform_build_dir="${BUILD_DIR}/${name}/${arch}"
    debug "Build directory: ${platform_build_dir}"
    
    # Determine OpenSSL library path (CORRECTED)
    local openssl_lib_path="${OPENSSL_BASE}/${name}"
    debug "OpenSSL path: ${openssl_lib_path}"
    
    # Verify OpenSSL exists before building (MODIFIED CHECK)
    if [[ ! -d "${openssl_lib_path}" ]]; then
        echo "ERROR: Missing OpenSSL for ${name} at ${openssl_lib_path}"
        exit 1
    fi
    if [[ ! -f "${openssl_lib_path}/lib/libssl.a" ]]; then
        echo "ERROR: Missing OpenSSL libraries for ${name}"
        exit 1
    fi

    mkdir -p "${platform_build_dir}"
    pushd "${platform_build_dir}" > /dev/null

    # Determine host triple and version flag
    local host=""
    local version_flag=""
    case "${sdk}" in
        iphoneos)
            host="arm64-apple-ios"
            version_flag="-mios-version-min"
            ;;
        iphonesimulator)
            if [[ "${arch}" == "x86_64" ]]; then
                host="x86_64-apple-darwin"
            else
                host="arm64-apple-darwin"
            fi
            version_flag="-mios-simulator-version-min"
            ;;
        macosx)
            if [[ "${arch}" == "x86_64" ]]; then
                host="x86_64-apple-darwin"
            else
                host="arm64-apple-darwin"
            fi
            version_flag="-mmacosx-version-min"
            ;;
    esac
    debug "Host triple: ${host}"
    debug "Version flag: ${version_flag}"

    # Set compiler and flags
    export CC="$(xcrun --sdk ${sdk} --find clang)"
    export CFLAGS="-arch ${arch} -isysroot ${sdk_path} ${version_flag}=${min_version} -I${openssl_lib_path}/include"
    export LDFLAGS="-L${openssl_lib_path}/lib"
    export CPPFLAGS="-I${openssl_lib_path}/include"
    
    debug "CC: ${CC}"
    debug "CFLAGS: ${CFLAGS}"
    debug "LDFLAGS: ${LDFLAGS}"
    debug "CPPFLAGS: ${CPPFLAGS}"
    debug "PKG_CONFIG_PATH: ${PKG_CONFIG_PATH}"
    debug "OpenSSL include path contents: $(ls ${openssl_lib_path}/include)"

    # Configure FreeTDS
    echo "Configuring FreeTDS for ${name} ${arch}..."
    local configure_args=(
        --enable-msdblib
        --disable-apps
        --disable-server
        --disable-pool
        --disable-odbc
        --with-tdsver=${TDS_VERSION}
        --prefix="${platform_build_dir}/install"
        --disable-dependency-tracking
        --enable-silent-rules
        --enable-static
        --disable-rpath
        --disable-debug
        --host="${host}"
    )

    # Only add OpenSSL flag if not building for iOS-simulator-arm64
    if [[ "${name}" != "iOS-simulator-arm64" ]]; then
        configure_args+=(--with-openssl="${openssl_lib_path}/lib")
    fi

    debug "Configure args: ${configure_args[@]}"
    
    # Run configure with full output
    "${SRC_DIR}/freetds-${FREETDS_VERSION}/configure" "${configure_args[@]}" || {
        echo "ERROR: Configure failed for ${name} ${arch}"
        exit 1
    }

    # Build and install (show full output)
    echo "Building FreeTDS..."
    if ! make -j$(sysctl -n hw.ncpu); then
        echo "ERROR: Build failed for ${name} ${arch}"
        exit 1
    fi
    
    echo "Installing..."
    if ! make install; then
        echo "ERROR: Install failed for ${name} ${arch}"
        exit 1
    fi

    popd > /dev/null
}

# Main execution
echo "Starting build process..."
verify_xcode

# Only cleanup on success
#trap 'if [[ $? -eq 0 ]]; then cleanup; fi' EXIT

for platform in "${PLATFORMS[@]}"; do
    IFS=',' read -r name sdk arch min_version <<< "${platform}"
    build_for_platform "${name}" "${sdk}" "${arch}" "${min_version}"
done

# iOS Device
mkdir -p "${LIBRARY_DIR}/iOS/lib"
lipo -create \
    "${BUILD_DIR}/iOS/arm64/install/lib/libsybdb.a" \
    "${BUILD_DIR}/iOS-arm64e/arm64e/install/lib/libsybdb.a" \
    -output "${LIBRARY_DIR}/iOS/lib/libsybdb.a"
lipo -create \
    "${BUILD_DIR}/iOS/arm64/install/lib/libct.a" \
    "${BUILD_DIR}/iOS-arm64e/arm64e/install/lib/libct.a" \
    -output "${LIBRARY_DIR}/iOS/lib/libct.a"

mkdir -p "${LIBRARY_DIR}/iOS-arm64e/lib"
mkdir -p "${LIBRARY_DIR}/iOS-arm64e/include"
cp -R "${BUILD_DIR}/iOS-arm64e/arm64e/install/include/"* "${LIBRARY_DIR}/iOS-arm64e/include/"
cp "${BUILD_DIR}/iOS-arm64e/arm64e/install/lib/libsybdb.a" "${LIBRARY_DIR}/iOS-arm64e/lib/libsybdb.a"
cp "${BUILD_DIR}/iOS-arm64e/arm64e/install/lib/libct.a" "${LIBRARY_DIR}/iOS-arm64e/lib/libct.a"

mkdir -p "${LIBRARY_DIR}/iOS-arm64/lib"
mkdir -p "${LIBRARY_DIR}/iOS-arm64/include"
cp -R "${BUILD_DIR}/iOS/arm64/install/include/"* "${LIBRARY_DIR}/iOS-arm64/include/"
cp "${BUILD_DIR}/iOS/arm64/install/lib/libsybdb.a" "${LIBRARY_DIR}/iOS-arm64/lib/libsybdb.a"
cp "${BUILD_DIR}/iOS/arm64/install/lib/libct.a" "${LIBRARY_DIR}/iOS-arm64/lib/libct.a"


mkdir -p "${LIBRARY_DIR}/iOS-simulator-x86_64/lib"
mkdir -p "${LIBRARY_DIR}/iOS-simulator-x86_64/include"
cp -R "${BUILD_DIR}/iOS-simulator/x86_64/install/include/"* "${LIBRARY_DIR}/iOS-simulator-x86_64/include/"
cp "${BUILD_DIR}/iOS-simulator/x86_64/install/lib/libsybdb.a" "${LIBRARY_DIR}/iOS-simulator-x86_64/lib/libsybdb.a"
cp "${BUILD_DIR}/iOS-simulator/x86_64/install/lib/libct.a" "${LIBRARY_DIR}/iOS-simulator-x86_64/lib/libct.a"

# Add iOS-simulator-arm64 output
mkdir -p "${LIBRARY_DIR}/iOS-simulator-arm64/lib"
mkdir -p "${LIBRARY_DIR}/iOS-simulator-arm64/include"
cp -R "${BUILD_DIR}/iOS-simulator-arm64/arm64/install/include/"* "${LIBRARY_DIR}/iOS-simulator-arm64/include/"
cp "${BUILD_DIR}/iOS-simulator-arm64/arm64/install/lib/libsybdb.a" "${LIBRARY_DIR}/iOS-simulator-arm64/lib/libsybdb.a"
cp "${BUILD_DIR}/iOS-simulator-arm64/arm64/install/lib/libct.a" "${LIBRARY_DIR}/iOS-simulator-arm64/lib/libct.a"

mkdir -p "${LIBRARY_DIR}/macOS-x86_64/lib"
cp "${BUILD_DIR}/macOS/x86_64/install/lib/libsybdb.a" "${LIBRARY_DIR}/macOS-x86_64/lib/libsybdb.a"
cp "${BUILD_DIR}/macOS/x86_64/install/lib/libct.a" "${LIBRARY_DIR}/macOS-x86_64/lib/libct.a"

mkdir -p "${LIBRARY_DIR}/macOS-arm64/lib"
mkdir -p "${LIBRARY_DIR}/macOS-arm64/include"
cp -R "${BUILD_DIR}/macOS-arm64/arm64/install/include/"* "${LIBRARY_DIR}/macOS-arm64/include/"
cp "${BUILD_DIR}/macOS-arm64/arm64/install/lib/libsybdb.a" "${LIBRARY_DIR}/macOS-arm64/lib/libsybdb.a"
cp "${BUILD_DIR}/macOS-arm64/arm64/install/lib/libct.a" "${LIBRARY_DIR}/macOS-arm64/lib/libct.a"

# Copy headers (mirror OpenSSL structure)
for platform in iOS iOS-arm64e macOS-x86_64; do
    mkdir -p "${LIBRARY_DIR}/${platform}/include"
    cp -R "${BUILD_DIR}/iOS/arm64/install/include/"* "${LIBRARY_DIR}/${platform}/include/"
done

echo "Build complete! Library structure:"
tree "${LIBRARY_DIR}"
