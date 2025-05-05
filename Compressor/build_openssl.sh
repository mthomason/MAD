#!/bin/bash
set -e

# Configuration
ROOT_DIR=$(pwd)
OPENSSL_TAR="openssl-3.4.1.tar.gz"
OPENSSL_SRC_DIR="${ROOT_DIR}/openssl-3.4.1"
BUILD_DIR="${ROOT_DIR}/openssl-build"
OUTPUT_DIR="${ROOT_DIR}/openssl-universal"

# Platforms to build
PLATFORMS=(
  "iPhoneOS arm64 ios64-cross"
  "iPhoneOS arm64e ios64-cross"
  "iPhoneSimulator x86_64 iossimulator-xcrun"
  "iPhoneSimulator arm64 iossimulator-xcrun"
  "macosx arm64 darwin64-arm64-cc"
  "macosx x86_64 darwin64-x86_64-cc"
)

# Clean previous builds
rm -rf "${BUILD_DIR}" "${OUTPUT_DIR}"
mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"

# Download OpenSSL source
if [ ! -d "${OPENSSL_SRC_DIR}" ]; then
  curl -L https://github.com/openssl/openssl/releases/download/openssl-3.4.1/openssl-3.4.1.tar.gz -o "${OPENSSL_TAR}"
  tar xzf "${OPENSSL_TAR}"
fi

# Build OpenSSL for each platform
declare -a CRYPTO_PATHS
declare -a SSL_PATHS
for PLATFORM_INFO in "${PLATFORMS[@]}"; do
  IFS=' ' read -r PLATFORM ARCH TARGET <<< "${PLATFORM_INFO}"
  echo "Building OpenSSL for ${PLATFORM} (${ARCH})..."

  BUILD_PATH="${BUILD_DIR}/${PLATFORM}-${ARCH}"
  mkdir -p "${BUILD_PATH}" && cd "${BUILD_PATH}"

  # Configure environment for iOS
  if [[ "${PLATFORM}" == "iPhoneOS" || "${PLATFORM}" == "iPhoneSimulator" ]]; then
    export CROSS_TOP=$(xcode-select -p)/Platforms/${PLATFORM}.platform/Developer
    export CROSS_SDK=${PLATFORM}.sdk
    export PATH="${CROSS_TOP}/../usr/bin:${PATH}"
  fi

  # Configure OpenSSL
  "${OPENSSL_SRC_DIR}/Configure" \
    ${TARGET} \
    no-shared \
    no-asm \
    no-deprecated \
    --prefix="${BUILD_PATH}/install" \
    --openssldir="${BUILD_PATH}/install" \
    -arch "${ARCH}"

  # Build and install
  make -j$(sysctl -n hw.ncpu)
  make install_sw

  # Collect libraries
  CRYPTO_PATH="${BUILD_PATH}/install/lib/libcrypto.a"
  SSL_PATH="${BUILD_PATH}/install/lib/libssl.a"

  if [ -f "${CRYPTO_PATH}" ] && [ -f "${SSL_PATH}" ]; then
    CRYPTO_PATHS+=("${CRYPTO_PATH}")
    SSL_PATHS+=("${SSL_PATH}")
  else
    echo "Error: OpenSSL libraries not found for ${PLATFORM} ${ARCH}"
    exit 1
  fi
done

# Create universal libraries
lipo -create "${CRYPTO_PATHS[@]}" -output "${OUTPUT_DIR}/libcrypto-universal.a"
lipo -create "${SSL_PATHS[@]}" -output "${OUTPUT_DIR}/libssl-universal.a"

echo "Universal OpenSSL libraries built:"
echo "- ${OUTPUT_DIR}/libcrypto-universal.a"
echo "- ${OUTPUT_DIR}/libssl-universal.a"
