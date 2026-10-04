#!/bin/bash
#
#  Recipe for zlib.  zlib's configure builds in-source, so each arch gets its
#  own copy of the source tree.  CC carries the arch, CFLAGS the sysroot and
#  deployment target -- the pattern the old build_zlib.sh used.

set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

MANIFEST_FLAGS="configure: --static; opt: -O3"

fetch_source "${URL}" "${SHA256}"

HEADERS_READY=0
for platform in ${PLATFORMS}; do
	for arch in $(platform_archs "${platform}"); do
		outdir="$(arch_build_dir "${platform}" "${arch}")"
		rm -rf "${outdir}"
		mkdir -p "${outdir}"
		cp -R "${SRC_ROOT}/." "${outdir}/src/"
		(
			cd "${outdir}/src"
			export CC="$(xcrun --sdk "$(platform_sdk "${platform}")" --find clang) -arch ${arch}"
			export CFLAGS="$(sysroot_flags "${platform}") -O3"
			export LDFLAGS=""
			export AR="$(xcrun --sdk "$(platform_sdk "${platform}")" --find ar)"
			export RANLIB="$(xcrun --sdk "$(platform_sdk "${platform}")" --find ranlib)"
			./configure --prefix="${outdir}" --static
			make -j"$(sysctl -n hw.ncpu)"
			make install
		)
		mv "${outdir}/lib/libz.a" "${outdir}/libz.a"
		if [[ "${HEADERS_READY}" == "0" ]]; then
			SRC_HEADERS_DIR="${outdir}/include"
			HEADERS_READY=1
		fi
	done
	lipo_platform "${platform}" libz.a
	install_headers_from "${platform}"
done

finish_library libz.a
