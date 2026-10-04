#!/bin/bash
#
#  Recipe for FreeTDS.  Depends on the openssl recipe (matrix deps): every
#  slice links our per-platform openssl install.  config.guess/config.sub
#  are refreshed from savannah, as the old build_tds.sh did, because the
#  tarball's copies predate the arm64-apple-ios triple.

set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

MANIFEST_FLAGS="configure: --enable-msdblib --disable-apps --disable-server --disable-pool --disable-odbc --with-tdsver=7.4 --enable-static --disable-rpath --disable-debug"

fetch_source "${URL}" "${SHA256}"

# Refreshed autoconf config files, cached in media/.
for cfgfile in config.guess config.sub; do
	if [[ ! -f "${MEDIA_DIR}/${cfgfile}" ]]; then
		curl -fsSL -o "${MEDIA_DIR}/${cfgfile}" \
			"https://git.savannah.gnu.org/cgit/config.git/plain/${cfgfile}" \
			|| die "failed to download ${cfgfile}"
	fi
	cp "${MEDIA_DIR}/${cfgfile}" "${SRC_ROOT}/${cfgfile}"
	chmod +x "${SRC_ROOT}/${cfgfile}"
done

host_triple() { # platform arch
	case "$1" in
		ios) echo arm64-apple-ios ;;
		simulator | macosx) echo "$2-apple-darwin" ;;
	esac
}

HEADERS_READY=0
for platform in ${PLATFORMS}; do
	sdk="$(platform_sdk "${platform}")"
	openssl_install="${BUILD_DIR}/openssl/${platform}/install"
	[[ -d "${openssl_install}/lib" ]] \
		|| die "openssl ${platform} install missing -- build openssl first"
	for arch in $(platform_archs "${platform}"); do
		outdir="$(arch_build_dir "${platform}" "${arch}")"
		rm -rf "${outdir}"
		mkdir -p "${outdir}"
		(
			cd "${outdir}"
			export CC="$(xcrun --sdk "${sdk}" --find clang)"
			export CFLAGS="-arch ${arch} $(sysroot_flags "${platform}") -I${openssl_install}/include"
			export CPPFLAGS="$(sysroot_flags "${platform}") -I${openssl_install}/include"
			export LDFLAGS="-L${openssl_install}/lib"
			"${SRC_ROOT}/configure" \
				--enable-msdblib \
				--disable-apps \
				--disable-server \
				--disable-pool \
				--disable-odbc \
				--with-tdsver=7.4 \
				--prefix="${outdir}/install" \
				--disable-dependency-tracking \
				--enable-silent-rules \
				--enable-static \
				--disable-rpath \
				--disable-debug \
				--host="$(host_triple "${platform}" "${arch}")" \
				--with-openssl="${openssl_install}"
			make -j"$(sysctl -n hw.ncpu)"
			make install
		)
		cp "${outdir}/install/lib/libct.a" "${outdir}/libct.a"
		cp "${outdir}/install/lib/libsybdb.a" "${outdir}/libsybdb.a"
		if [[ -f "${outdir}/install/lib/libtds.a" ]]; then
			cp "${outdir}/install/lib/libtds.a" "${outdir}/libtds.a"
		fi
		if [[ "${HEADERS_READY}" == "0" ]]; then
			SRC_HEADERS_DIR="${outdir}/install/include"
			HEADERS_READY=1
		fi
	done
	libs=(libct.a libsybdb.a)
	[[ -f "$(arch_build_dir "${platform}" "$(platform_archs "${platform}" | awk '{print $1}')")/libtds.a" ]] && libs+=(libtds.a)
	lipo_platform "${platform}" "${libs[@]}"
	# One library per xcframework slice identifier: ct, sybdb and tds
	# merge into libfreetds.a, which is what consumers link.
	install="$(platform_install_dir "${platform}")"
	merge_inputs=("${install}/lib/libct.a" "${install}/lib/libsybdb.a")
	[[ -f "${install}/lib/libtds.a" ]] && merge_inputs+=("${install}/lib/libtds.a")
	xcrun libtool -static -o "${install}/lib/libfreetds.a" "${merge_inputs[@]}"
	install_headers_from "${platform}"
done

finish_library libfreetds.a
