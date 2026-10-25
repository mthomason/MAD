#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  Recipe for libpng.  Depends on the zlib recipe: every slice links our
#  zlib install instead of the system libz (the old build_png.sh used the
#  system one; this is the deliberate change that lets MADBarcodes drop its
#  libz.tbd reference).

set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

MANIFEST_FLAGS="configure: --enable-shared=no --enable-static=yes --disable-dependency-tracking; zlib: ours"

fetch_source "${URL}" "${SHA256}"

host_triple() { # arch
	case "$1" in
		arm64 | arm64e) echo aarch64-apple-darwin ;;
		x86_64) echo x86_64-apple-darwin ;;
	esac
}

HEADERS_READY=0
for platform in ${PLATFORMS}; do
	sdk="$(platform_sdk "${platform}")"
	sdk_path="$(xcrun --sdk "${sdk}" --show-sdk-path)"
	zlib_install="${BUILD_DIR}/zlib/${platform}/install"
	[[ -d "${zlib_install}/lib" ]] || die "zlib ${platform} install missing -- build zlib first"
	for arch in $(platform_archs "${platform}"); do
		outdir="$(arch_build_dir "${platform}" "${arch}")"
		rm -rf "${outdir}"
		mkdir -p "${outdir}"
		(
			cd "${outdir}"
			export CC="$(xcrun --sdk "${sdk}" --find clang) -arch ${arch}"
			export CFLAGS="$(sysroot_flags "${platform}") -I${zlib_install}/include"
			# The pnglibconf preprocess runs $(CC) -E with CPPFLAGS only, so
			# the sysroot must be here too or <sys/types.h> cannot resolve.
			export CPPFLAGS="$(sysroot_flags "${platform}") -I${sdk_path}/usr/include -I${zlib_install}/include"
			export LDFLAGS="-L${zlib_install}/lib"
			"${SRC_ROOT}/configure" \
				--host="$(host_triple "${arch}")" \
				--prefix="${outdir}/install" \
				--enable-shared=no \
				--enable-static=yes \
				--disable-dependency-tracking
			make -j"$(sysctl -n hw.ncpu)"
			make install
		)
		cp "${outdir}/install/lib/libpng.a" "${outdir}/libpng.a"
		if [[ "${HEADERS_READY}" == "0" ]]; then
			SRC_HEADERS_DIR="${outdir}/install/include"
			HEADERS_READY=1
		fi
	done
	lipo_platform "${platform}" libpng.a
	install_headers_from "${platform}"
done

finish_library libpng.a
