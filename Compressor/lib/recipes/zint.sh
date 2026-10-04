#!/bin/bash
#
#  Recipe for zint.  2.16 builds with cmake; the 2.4.2-era direct compile
#  and the local patch (Compressor/patches/zint-2.4.2-mad.patch) are
#  retired -- ZBarcode_Encode_and_Buffer, which the patch backported, is
#  upstream API, and the wrapper's BARCODE_* names all survive as aliases.

set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

MANIFEST_FLAGS="cmake: ZINT_SHARED=OFF ZINT_STATIC=ON ZINT_FRONTEND=OFF ZINT_USE_PNG=ON; png: ours"

fetch_source "${URL}" "${SHA256}"

HEADERS_READY=0
for platform in ${PLATFORMS}; do
	sdk="$(platform_sdk "${platform}")"
	sdk_path="$(xcrun --sdk "${sdk}" --show-sdk-path)"
	libpng_install="${BUILD_DIR}/libpng/${platform}/install"
	zlib_install="${BUILD_DIR}/zlib/${platform}/install"
	[[ -f "${libpng_install}/lib/libpng.a" ]] || die "libpng ${platform} install missing -- build libpng first"
	for arch in $(platform_archs "${platform}"); do
		outdir="$(arch_build_dir "${platform}" "${arch}")"
		rm -rf "${outdir}"
		mkdir -p "${outdir}"
		(
			cd "${outdir}"
			cmake "${SRC_ROOT}" \
				-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
				-DCMAKE_SYSTEM_NAME=Darwin \
				-DCMAKE_OSX_SYSROOT="${sdk_path}" \
				-DCMAKE_OSX_ARCHITECTURES="${arch}" \
				-DCMAKE_OSX_DEPLOYMENT_TARGET="$(platform_min_version "${platform}")" \
				-DCMAKE_C_COMPILER="$(xcrun --sdk "${sdk}" --find clang)" \
				-DZINT_SHARED=OFF \
				-DZINT_STATIC=ON \
				-DZINT_FRONTEND=OFF \
				-DZINT_USE_PNG=ON \
				-DPNG_INCLUDE_DIR="${libpng_install}/include" \
				-DPNG_LIBRARY="${libpng_install}/lib/libpng.a" \
				-DZLIB_INCLUDE_DIR="${zlib_install}/include" \
				-DZLIB_LIBRARY="${zlib_install}/lib/libz.a"
			cmake --build . --target zint-static -j"$(sysctl -n hw.ncpu)"
		)
		cp "$(find "${outdir}" -name libzint.a | head -1)" "${outdir}/libzint.a"
		if [[ "${HEADERS_READY}" == "0" ]]; then
			mkdir -p "${outdir}/include"
			cp "${SRC_ROOT}/backend/zint.h" "${outdir}/include/"
			SRC_HEADERS_DIR="${outdir}/include"
			HEADERS_READY=1
		fi
	done
	lipo_platform "${platform}" libzint.a
	install_headers_from "${platform}"
done

finish_library libzint.a
