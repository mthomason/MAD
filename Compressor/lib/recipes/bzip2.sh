#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  Recipe for bzip2.  Plain make with a fresh source copy per arch, as the
#  old build_bzip2.sh did -- bzip2's Makefile does not support out-of-tree
#  or repeated in-tree builds cleanly.

set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

MANIFEST_FLAGS="make: libbz2.a; opt: -O3 -DNDEBUG"

fetch_source "${URL}" "${SHA256}"

HEADERS_READY=0
for platform in ${PLATFORMS}; do
	sdk="$(platform_sdk "${platform}")"
	for arch in $(platform_archs "${platform}"); do
		outdir="$(arch_build_dir "${platform}" "${arch}")"
		rm -rf "${outdir}"
		mkdir -p "${outdir}/src"
		cp -R "${SRC_ROOT}/." "${outdir}/src/"
		(
			cd "${outdir}/src"
			cflags="-O3 -DNDEBUG -arch ${arch} $(sysroot_flags "${platform}")"
			make clean >/dev/null 2>&1 || true
			make libbz2.a -j"$(sysctl -n hw.ncpu)" \
				CC="$(xcrun --sdk "${sdk}" --find clang)" \
				CFLAGS="${cflags}" \
				LDFLAGS="${cflags}" \
				AR="$(xcrun --sdk "${sdk}" --find ar)" \
				RANLIB="$(xcrun --sdk "${sdk}" --find ranlib)"
			cp libbz2.a "${outdir}/libbz2.a"
			mkdir -p "${outdir}/include"
			cp *.h "${outdir}/include/"
		)
		if [[ "${HEADERS_READY}" == "0" ]]; then
			SRC_HEADERS_DIR="${outdir}/include"
			HEADERS_READY=1
		fi
	done
	lipo_platform "${platform}" libbz2.a
	install_headers_from "${platform}"
done

finish_library libbz2.a
