#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  Recipe for OpenSSL.  One out-of-tree Configure per arch, then install_sw
#  into a per-arch prefix.
#
#  The device and simulator slices use the legacy `iphoneos-cross` target,
#  whose cflags carry no -arch (the arch rides in CC, which is how arm64e
#  works) and whose sysroot comes from CROSS_TOP/CROSS_SDK -- the pattern the
#  build_openssl_thridparty.sh script used for 3.5.0.  The macOS slices use
#  darwin64-<arch>-cc, which supplies its own -arch.

set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

MANIFEST_FLAGS="configure: no-shared no-asm no-async; opt: -O3"

fetch_source "${URL}" "${SHA256}"

configure_target() { # platform arch -> openssl Configure target name
	case "$1" in
		ios | simulator) echo iphoneos-cross ;;
		macosx) echo "darwin64-$2-cc" ;;
	esac
}

HEADERS_READY=0
for platform in ${PLATFORMS}; do
	sdk="$(platform_sdk "${platform}")"
	for arch in $(platform_archs "${platform}"); do
		outdir="$(arch_build_dir "${platform}" "${arch}")"
		rm -rf "${outdir}"
		mkdir -p "${outdir}"

		cc="$(xcrun --sdk "${sdk}" --find clang)"
		if [[ "${platform}" == "macosx" ]]; then
			ccflags=""
			cflags="-isysroot $(xcrun --sdk macosx --show-sdk-path) $(sysroot_flags "${platform}") -O3"
		else
			ccflags="-arch ${arch}"
			cflags="$(sysroot_flags "${platform}") -O3"
		fi

		(
			cd "${outdir}"
			export CROSS_TOP="$(xcode-select -p)/Platforms/$( [[ "${platform}" == "ios" ]] && echo iPhoneOS || echo iPhoneSimulator ).platform/Developer"
			export CROSS_SDK="$( [[ "${platform}" == "ios" ]] && echo iPhoneOS || echo iPhoneSimulator )$(xcrun --sdk "${sdk}" --show-sdk-version).sdk"
			"${SRC_ROOT}/Configure" \
				"$(configure_target "${platform}" "${arch}")" \
				no-shared no-asm no-async \
				--prefix="${outdir}/install" \
				--openssldir="${outdir}/install" \
				CC="${cc} ${ccflags}" \
				CFLAGS="${cflags}" \
				LDFLAGS="${cflags}"
			make -j"$(sysctl -n hw.ncpu)" > make.log 2>&1
			make install_sw > install.log 2>&1
		)

		cp "${outdir}/install/lib/libcrypto.a" "${outdir}/libcrypto.a"
		cp "${outdir}/install/lib/libssl.a" "${outdir}/libssl.a"
		if [[ "${HEADERS_READY}" == "0" ]]; then
			SRC_HEADERS_DIR="${outdir}/install/include"
			HEADERS_READY=1
		fi
	done
	lipo_platform "${platform}" libcrypto.a libssl.a
	# One library per xcframework slice identifier: crypto and ssl merge
	# into libopenssl.a, which is what consumers link.
	xcrun libtool -static -o "$(platform_install_dir "${platform}")/lib/libopenssl.a" \
		"$(platform_install_dir "${platform}")/lib/libcrypto.a" \
		"$(platform_install_dir "${platform}")/lib/libssl.a"
	install_headers_from "${platform}"
done

finish_library libopenssl.a
