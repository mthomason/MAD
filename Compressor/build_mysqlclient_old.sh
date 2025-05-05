#!/bin/bash
set -eo pipefail
shopt -s extglob

# ---------------------------
# Configuration
# ---------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}"

MYSQL_TAR="${ROOT_DIR}/media/mysql-8.0.41.tar.gz"
OUTPUT_DIR="${ROOT_DIR}/library/libmysqlclient"
WORK_DIR="${ROOT_DIR}/build_temp"
DEPLOYMENT_TARGET="14.0"

# Boost Configuration - MUST use .tar.bz2 for MySQL
BOOST_VERSION="1_77_0"
BOOST_VERSION_DOTS="1.77.0"
BOOST_URL="https://archives.boost.io/release/${BOOST_VERSION_DOTS}/source/boost_${BOOST_VERSION}.tar.gz"
# Bison Configuration
BISON_MIN_VERSION="3.0.4"
HOMEBREW_BISON_PATH="/opt/homebrew/Cellar/bison/3.8.2/bin/bison"

# OpenSSL paths
OPENSSL_INCLUDE="${ROOT_DIR}/library/openssl/include"
OPENSSL_DEVICE_LIBS=("${ROOT_DIR}/library/openssl/framework/openssl-ios-armv7_armv7s_arm64_arm64e.a")
OPENSSL_SIM_LIBS=("${ROOT_DIR}/library/openssl/framework/openssl-ios-i386_x86_64_arm64-simulator.a")

# Verify OpenSSL files exist
if [[ ! -d "${OPENSSL_INCLUDE}" ]]; then
  echo "ERROR: OpenSSL include directory not found at ${OPENSSL_INCLUDE}"
  exit 1
fi
if [[ ! -f "${OPENSSL_DEVICE_LIBS[0]}" ]]; then
  echo "ERROR: OpenSSL device library not found at ${OPENSSL_DEVICE_LIBS[0]}"
  exit 1
fi
if [[ ! -f "${OPENSSL_SIM_LIBS[0]}" ]]; then
  echo "ERROR: OpenSSL simulator library not found at ${OPENSSL_SIM_LIBS[0]}"
  exit 1
fi

# Architectures to build (name sdk openssl_lib)
ARCHS=(
  "arm64  iphoneos      ${OPENSSL_DEVICE_LIBS[0]}"
  "x86_64 iphonesimulator ${OPENSSL_SIM_LIBS[0]}"
  "arm64  iphonesimulator ${OPENSSL_SIM_LIBS[0]}"
)

# ---------------------------
# Cleanup and Setup
# ---------------------------
echo "Cleaning work directories..."
rm -rf "${WORK_DIR}" "${OUTPUT_DIR}"
mkdir -p "${WORK_DIR}" "${OUTPUT_DIR}/include"

# ---------------------------
# Extract MySQL Source
# ---------------------------
echo "Extracting MySQL source..."
tar xzf "${MYSQL_TAR}" -C "${WORK_DIR}"
MYSQL_SRC="${WORK_DIR}/mysql-8.0.41"

# Verify source extraction
if [[ ! -d "${MYSQL_SRC}" ]]; then
  echo "ERROR: MySQL source not found at ${MYSQL_SRC}"
  exit 1
fi

# ---------------------------
# Patch for Xcode compatibility
# ---------------------------
echo "Patching MySQL build system..."
find "${MYSQL_SRC}/cmake" -type f -exec sed -i '' \
  -e 's/XCODE_VERSION VERSION_GREATER_EQUAL 10/XCODE_VERSION VERSION_GREATER_EQUAL 8/' \
  -e 's/Clang 7.1/Clang 10.0/' \
  -e 's/CMAKE_CXX_COMPILER_VERSION VERSION_LESS 7.1/CMAKE_CXX_COMPILER_VERSION VERSION_LESS 10.0/' \
  {} +

# ---------------------------
# Boost Handling (Critical Fixes)
# ---------------------------
BOOST_DIR="${WORK_DIR}/boost"
BOOST_TAR_FILENAME="boost_${BOOST_VERSION}.tar.bz2"
BOOST_TAR="${BOOST_DIR}/${BOOST_TAR_FILENAME}"
BOOST_EXTRACTED_DIR="${BOOST_DIR}/boost_${BOOST_VERSION}"

# Create boost directory
mkdir -p "${BOOST_DIR}"

# Download Boost if missing
if [[ ! -f "${BOOST_TAR}" ]]; then
  echo "Downloading Boost from ${BOOST_URL}..."
  if ! curl -L -o "${BOOST_TAR}" "${BOOST_URL}"; then
    echo "ERROR: Failed to download Boost archive"
    exit 1
  fi
fi

# Extract Boost (using bzip2 decompression)
if [[ ! -d "${BOOST_EXTRACTED_DIR}" ]]; then
  echo "Extracting Boost..."
  tar xjf "${BOOST_TAR}" -C "${BOOST_DIR}"
fi

# Verify Boost extraction
if [[ ! -f "${BOOST_EXTRACTED_DIR}/boost/version.hpp" ]]; then
  echo "ERROR: Boost extraction failed - version.hpp not found"
  exit 1
fi

# Create version-specific symlink for MySQL's build system
BOOST_LINK_DIR="${BOOST_DIR}/boost_1_77_0"
if [[ ! -L "${BOOST_LINK_DIR}" ]]; then
  ln -s "${BOOST_EXTRACTED_DIR}" "${BOOST_LINK_DIR}"
fi

# ---------------------------
# Bison Version Check
# ---------------------------
check_bison_version() {
  local bison_path="$1"
  local version=$(${bison_path} --version | head -n1 | awk '{print $NF}')
  if [[ "$(printf '%s\n' "${BISON_MIN_VERSION}" "${version}" | sort -V | head -n1)" != "${BISON_MIN_VERSION}" ]]; then
    return 1
  fi
  return 0
}

# Try to find suitable bison
BISON_EXECUTABLE="$(command -v bison)"
if [[ -x "${HOMEBREW_BISON_PATH}" ]]; then
  # Try Homebrew bison first
  BISON_EXECUTABLE="${HOMEBREW_BISON_PATH}"
fi

# Verify bison version
if ! check_bison_version "${BISON_EXECUTABLE}"; then
  echo "ERROR: Bison >= ${BISON_MIN_VERSION} required but found:"
  ${BISON_EXECUTABLE} --version || true
  echo -e "\nInstall latest Bison using:"
  echo "  brew install bison"
  echo "Then ensure it's in your PATH before system bison"
  exit 1
fi

# ---------------------------
# Build for Each Architecture
# ---------------------------
declare -a BUILT_LIBS

for entry in "${ARCHS[@]}"; do
    IFS=' ' read -ra ADDR <<< "$entry"
    ARCH=${ADDR[0]}
    SDK=${ADDR[1]}
    SSL_LIB=${ADDR[2]}

    echo -e "\n\n[ Building ${ARCH} (${SDK}) ]"

    BUILD_DIR="${WORK_DIR}/build_${ARCH}"
    mkdir -p "${BUILD_DIR}"

    # Absolute path to SD
    SDK_PATH="$(xcrun --sdk ${SDK} --show-sdk-path)"

    cd "${BUILD_DIR}"

echo "cmake \"${MYSQL_SRC}\" \
    -DDOWNLOAD_BOOST=1 -DWITH_BOOST=\"${BOOST_DIR}\" \
    -DCMAKE_SYSTEM_NAME=\"Darwin\" \
    -DCMAKE_OSX_SYSROOT=\"${SDK_PATH}\" \
    -DCMAKE_OSX_ARCHITECTURES=\"${ARCH}\" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=\"${DEPLOYMENT_TARGET}\" \
    -DFORCE_UNSUPPORTED_COMPILER=1 \
    -DWITHOUT_SERVER=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DWITH_SSL=system \
    -DCURSES_INCLUDE_PATH=\"/opt/homebrew/opt/ncurses/include\" \
    -DCURSES_LIBRARY=\"/opt/homebrew/opt/ncurses/lib/libncurses.\" \
    -DOPENSSL_INCLUDE_DIR=\"${OPENSSL_INCLUDE}\" \
    -DOPENSSL_SSL_LIBRARY=\"${SSL_LIB}\" \
    -DOPENSSL_CRYPTO_LIBRARY=\"${SSL_LIB}\" \
    -DWITH_UNIT_TESTS=OFF \
    -DCMAKE_LIBEVENT_INCLUDE_DIRS=\"/opt/homebrew/opt/libevent/include\" \
    -DCMAKE_LIBEVENT_LIBRARIES=\"/opt/homebrew/opt/libevent/lib/libevent.dylib\""

done

exit

cmake "${MYSQL_SRC}" \
    -DDOWNLOAD_BOOST=1 -DWITH_BOOST="${BOOST_DIR}" \
    -DCMAKE_SYSTEM_NAME="Darwin" \
    -DCMAKE_OSX_SYSROOT="${SDK_PATH}" \
    -DCMAKE_OSX_ARCHITECTURES="${ARCH}" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}" \
    -DFORCE_UNSUPPORTED_COMPILER=1 \
    -DWITHOUT_SERVER=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DWITH_SSL=system \
    -DCURSES_INCLUDE_PATH="/opt/homebrew/opt/ncurses/include" \
    -DCURSES_LIBRARY="/opt/homebrew/opt/ncurses/lib/libncurses.dylib" \
    -DOPENSSL_INCLUDE_DIR="${OPENSSL_INCLUDE}" \
    -DOPENSSL_SSL_LIBRARY="${SSL_LIB}" \
    -DOPENSSL_CRYPTO_LIBRARY="${SSL_LIB}" \
    -DWITH_UNIT_TESTS=OFF \
    -DCMAKE_LIBEVENT_INCLUDE_DIRS="/opt/homebrew/opt/libevent/include" \
    -DCMAKE_LIBEVENT_LIBRARIES="/opt/homebrew/opt/libevent/lib/libevent.dylib"

    # Build only mysqlclient
    cmake --build . --target mysqlclient -- -j$(sysctl -n hw.logicalcpu)

    # Save built library
    BUILT_LIBS+=("${BUILD_DIR}/library_output_directory/libmysqlclient.a")
#done

# ---------------------------
# Create Universal Library
# ---------------------------
echo -e "\n\nCreating universal library..."
lipo -create "${BUILT_LIBS[@]}" -output "${OUTPUT_DIR}/libmysqlclient.a"

# ---------------------------
# Copy Headers
# ---------------------------
echo "Copying headers..."
cp -R "${MYSQL_SRC}/include/mysql" "${OUTPUT_DIR}/include/"

# ---------------------------
# Final Cleanup
# ---------------------------
rm -rf "${WORK_DIR}"
echo -e "\n\nDone! Universal library and headers in: ${OUTPUT_DIR}"
