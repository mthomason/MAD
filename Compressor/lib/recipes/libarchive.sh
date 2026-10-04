#!/bin/bash
#
#  Recipe for libarchive.  Depends on zlib and bzip2 (matrix deps): both
#  link from our installs now.  XML2 and LZMA stay on the system SDK -- the
#  MAD framework links the SDK's libxml2/libxz stubs, so archive must keep
#  using them too.

set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

MANIFEST_FLAGS="cmake: BZip2/ZLIB=ours XML2/LZMA=system, ZSTD/OPENSSL/LZ4/TEST=OFF, TAR/CPIO=ON"

fetch_source "${URL}" "${SHA256}"

HEADERS_READY=0
for platform in ${PLATFORMS}; do
	sdk="$(platform_sdk "${platform}")"
	sdk_path="$(xcrun --sdk "${sdk}" --show-sdk-path)"
	bzip2_install="${BUILD_DIR}/bzip2/${platform}/install"
	zlib_install="${BUILD_DIR}/zlib/${platform}/install"
	[[ -f "${bzip2_install}/lib/libbz2.a" ]] || die "bzip2 ${platform} install missing -- build bzip2 first"
	[[ -f "${zlib_install}/lib/libz.a" ]] || die "zlib ${platform} install missing -- build zlib first"
	for arch in $(platform_archs "${platform}"); do
		outdir="$(arch_build_dir "${platform}" "${arch}")"
		rm -rf "${outdir}"
		mkdir -p "${outdir}"
		(
			cd "${outdir}"
			cflags="-arch ${arch} $(sysroot_flags "${platform}") -I${sdk_path}/usr/include/libxml2"
			cmake "${SRC_ROOT}" \
				-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
				-DCMAKE_SYSTEM_NAME=Darwin \
				-DCMAKE_OSX_SYSROOT="${sdk_path}" \
				-DCMAKE_OSX_ARCHITECTURES="${arch}" \
				-DCMAKE_OSX_DEPLOYMENT_TARGET="$(platform_min_version "${platform}")" \
				-DCMAKE_C_COMPILER="$(xcrun --sdk "${sdk}" --find clang)" \
				-DCMAKE_CXX_COMPILER="$(xcrun --sdk "${sdk}" --find clang++)" \
				-DCMAKE_C_FLAGS="${cflags}" \
				-DCMAKE_CXX_FLAGS="${cflags}" \
				-DLIBXML2_INCLUDE_DIR="${sdk_path}/usr/include/libxml2" \
				-DLIBXML2_LIBRARIES="-lxml2" \
				-DENABLE_BZip2=ON \
				-DBZIP2_INCLUDE_DIR="${bzip2_install}/include" \
				-DBZIP2_LIBRARY="${bzip2_install}/lib/libbz2.a" \
				-DENABLE_XML2=ON \
				-DENABLE_ZLIB=ON \
				-DZLIB_LIBRARY="${zlib_install}/lib/libz.a" \
				-DZLIB_INCLUDE_DIR="${zlib_install}/include" \
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
			make -j"$(sysctl -n hw.ncpu)"
		)
		cp "${outdir}/libarchive/libarchive.a" "${outdir}/libarchive.a"
		if [[ "${HEADERS_READY}" == "0" ]]; then
			mkdir -p "${outdir}/include"
			cp "${SRC_ROOT}"/libarchive/*.h "${outdir}/include/"
			SRC_HEADERS_DIR="${outdir}/include"
			HEADERS_READY=1
		fi
	done
	lipo_platform "${platform}" libarchive.a
	install_headers_from "${platform}"
done

finish_library libarchive.a
