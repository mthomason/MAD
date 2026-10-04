#!/bin/bash
#
#  Recipe for zint.  The baseline is stock 2.4.2 plus the local
#  modifications the vendored MADBarcodes tree carried (Compressor/patches/
#  zint-2.4.2-mad.patch -- a ZBarcode_PNG_Buffer addition and 64-bit cast
#  fixups).  MADBarcodes always compiled the backend .c files straight into
#  the framework, so this recipe does the same into libzint.a; zint 2.4.2's
#  cmake builds SHARED only, which is not what we want.

set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

MANIFEST_FLAGS="compile: backend .c files direct (as MADBarcodes did); opt: -Os; png: ours; patch: zint-2.4.2-mad.patch"

fetch_source "${URL}" "${SHA256}"

patch -d "${SRC_ROOT}/backend" -p1 < "${COMPRESSOR_DIR}/patches/zint-2.4.2-mad.patch"

HEADERS_READY=0
for platform in ${PLATFORMS}; do
	sdk="$(platform_sdk "${platform}")"
	libpng_install="${BUILD_DIR}/libpng/${platform}/install"
	[[ -f "${libpng_install}/lib/libpng.a" ]] || die "libpng ${platform} install missing -- build libpng first"
	for arch in $(platform_archs "${platform}"); do
		outdir="$(arch_build_dir "${platform}" "${arch}")"
		rm -rf "${outdir}"
		mkdir -p "${outdir}/objects"
		(
			cd "${SRC_ROOT}/backend"
			for src in *.c; do
				xcrun --sdk "${sdk}" clang -c "${src}" \
					-o "${outdir}/objects/${src%.c}.o" \
					-w -Os \
					$(arch_cflags "${platform}" "${arch}") \
					-I. -I"${libpng_install}/include"
			done
		)
		xcrun ar rcs "${outdir}/libzint.a" "${outdir}"/objects/*.o
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
