#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  Recipe for PostgreSQL's client library (libpq).  Depends on the openssl
#  recipe (matrix deps): every slice links our per-platform openssl install.
#  Only the static client libraries (libpq.a, libpgcommon_shlib.a,
#  libpgport_shlib.a) and the public client headers are built and merged into
#  one libpq.a per slice; the server, CLI tools, and shared library are never
#  built.

set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

MANIFEST_FLAGS="configure: --with-ssl=openssl --without-readline --without-icu --without-zlib --without-lz4 --without-zstd --without-gssapi --without-ldap --without-pam --without-bonjour --disable-rpath; targets: libpgcommon_shlib.a libpgport_shlib.a libpq.a (merged)"

fetch_source "${URL}" "${SHA256}"

HEADERS_READY=0
for platform in ${PLATFORMS}; do
	sdk="$(platform_sdk "${platform}")"
	sdk_path="$(xcrun --sdk "${sdk}" --show-sdk-path)"
	openssl_install="${BUILD_DIR}/openssl/${platform}/install"
	[[ -d "${openssl_install}/lib" ]] \
		|| die "openssl ${platform} install missing -- build openssl first"
	for arch in $(platform_archs "${platform}"); do
		outdir="$(arch_build_dir "${platform}" "${arch}")"
		/bin/rm -rf "${outdir}"
		mkdir -p "${outdir}"
		(
			cd "${outdir}"
			host_arch="${arch}"
			[[ "${host_arch}" == "arm64e" ]] && host_arch="arm64"
			export CC="$(xcrun --sdk "${sdk}" --find clang)"
			export AR="$(xcrun --sdk "${sdk}" --find ar)"
			export RANLIB="$(xcrun --sdk "${sdk}" --find ranlib)"
			export STRIP="$(xcrun --sdk "${sdk}" --find strip)"
			export PG_SYSROOT="${sdk_path}"
			export CFLAGS="-O2 $(arch_cflags "${platform}" "${arch}") -I${openssl_install}/include"
			export CPPFLAGS="$(arch_cflags "${platform}" "${arch}") -I${openssl_install}/include"
			export LDFLAGS="$(arch_cflags "${platform}" "${arch}") -L${openssl_install}/lib"
			"${SRC_ROOT}/configure" \
				--prefix="${outdir}/install" \
				--host="${host_arch}-apple-darwin" \
				--build="aarch64-apple-darwin" \
				--with-template=darwin \
				--with-system-tzdata=/usr/share/zoneinfo \
				--with-ssl=openssl \
				--without-readline \
				--without-icu \
				--without-zlib \
				--without-lz4 \
				--without-zstd \
				--without-gssapi \
				--without-ldap \
				--without-pam \
				--without-bonjour \
				--disable-rpath

			ncpu="$(sysctl -n hw.ncpu)"
			make -C src/include NO_GENERATED_HEADERS=1 all
			make -C src/backend submake-catalog-headers
			make -C src/backend/utils errcodes.h
			mkdir -p src/include/utils
			/bin/cp -f src/backend/utils/errcodes.h src/include/utils/errcodes.h
			make -C src/common -j"${ncpu}" libpgcommon_shlib.a
			make -C src/port -j"${ncpu}" libpgport_shlib.a
			make -C src/interfaces/libpq -j"${ncpu}" SHLIB_PREREQS="" libpq.a

			mkdir -p "${outdir}/install/include/libpq"
			/bin/cp -f "${SRC_ROOT}/src/interfaces/libpq/libpq-fe.h" "${outdir}/install/include/"
			/bin/cp -f "${SRC_ROOT}/src/interfaces/libpq/libpq-events.h" "${outdir}/install/include/"
			/bin/cp -f "${SRC_ROOT}/src/include/postgres_ext.h" "${outdir}/install/include/"
			/bin/cp -f "${SRC_ROOT}/src/include/pg_config_manual.h" "${outdir}/install/include/"
			/bin/cp -f "${SRC_ROOT}/src/include/libpq/libpq-fs.h" "${outdir}/install/include/libpq/"
			/bin/cp -f "src/include/pg_config.h" "${outdir}/install/include/"
			/bin/cp -f "src/include/pg_config_ext.h" "${outdir}/install/include/"
			/bin/cp -f "src/include/pg_config_os.h" "${outdir}/install/include/"
			/bin/cp -f "src/include/catalog/pg_type_d.h" "${outdir}/install/include/"
		)
		/bin/cp -f "${outdir}/src/interfaces/libpq/libpq.a" "${outdir}/libpq_raw.a"
		/bin/cp -f "${outdir}/src/common/libpgcommon_shlib.a" "${outdir}/libpgcommon.a"
		/bin/cp -f "${outdir}/src/port/libpgport_shlib.a" "${outdir}/libpgport.a"
		if [[ "${HEADERS_READY}" == "0" ]]; then
			SRC_HEADERS_DIR="${outdir}/install/include"
			HEADERS_READY=1
		fi
	done
	lipo_platform "${platform}" libpq_raw.a libpgcommon.a libpgport.a
	# One library per xcframework slice identifier: merge libpq, libpgcommon
	# and libpgport into libpq.a so consumers link a single archive.
	install="$(platform_install_dir "${platform}")"
	xcrun libtool -static -o "${install}/lib/libpq.a" \
		"${install}/lib/libpq_raw.a" \
		"${install}/lib/libpgcommon.a" \
		"${install}/lib/libpgport.a"
	/bin/rm -f "${install}/lib/libpq_raw.a" "${install}/lib/libpgcommon.a" "${install}/lib/libpgport.a"
	install_headers_from "${platform}"
done

finish_library libpq.a
