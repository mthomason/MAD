#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  Recipe for MariaDB Connector/C.  Depends on the openssl and zlib recipes
#  (matrix deps): every slice links the per-platform openssl and zlib
#  installs.  This replaces the mysqlclient recipe -- Connector/C is the MySQL
#  C API reimplemented under LGPL-2.0-or-later, so there is no host-tool
#  two-stage build, no try_run preset farm and no bundled boost.  Its one
#  run-based configure probe (the LibreSSL check, CMakeLists.txt s.402) is
#  answered by the cross preset below; we link OpenSSL, not LibreSSL.

set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

# Connector/C 3.4.11 realities this recipe encodes: the static library target
# is `mariadbclient` (libmariadb is hardcoded shared on UNIX), the DEFAULT
# install layout puts headers under include/mariadb/ (flattened below so
# <mysql.h> resolves from the canonical include root), and the MySQL 8 auth
# plugins default to dynamic .so builds -- the two MADMySQL needs are made
# static, the rest disabled so no plugin .so ships at all.
MANIFEST_FLAGS="cmake: WITH_SSL=OPENSSL WITH_EXTERNAL_ZLIB=ON WITH_CURL=OFF WITH_UNIT_TESTS=OFF; plugins: caching_sha2_password/sha256_password static, others off; openssl/zlib: per-platform installs"

fetch_source "${URL}" "${SHA256}"

# The LibreSSL probe is a TRY_RUN: answered with the OpenSSL outcome
# (exit code 1, no output) so configure never executes a host binary.
CROSS_PRESET="${BUILD_DIR}/${LIB}/cross-preset.cmake"
cat > "${CROSS_PRESET}" <<'EOF'
set(LIBRESSL_RESULT "1" CACHE STRING "")
set(LIBRESSL_RESULT__TRYRUN_OUTPUT "" CACHE STRING "")
EOF

HEADERS_READY=0
for platform in ${PLATFORMS}; do
	sdk="$(platform_sdk "${platform}")"
	sdk_path="$(xcrun --sdk "${sdk}" --show-sdk-path)"
	openssl_install="${BUILD_DIR}/openssl/${platform}/install"
	zlib_install="${BUILD_DIR}/zlib/${platform}/install"
	[[ -d "${openssl_install}/lib" ]] || die "openssl ${platform} install missing -- build openssl first"
	[[ -d "${zlib_install}/lib" ]] || die "zlib ${platform} install missing -- build zlib first"
	for arch in $(platform_archs "${platform}"); do
		outdir="$(arch_build_dir "${platform}" "${arch}")"
		rm -rf "${outdir}"
		mkdir -p "${outdir}"
		(
			cd "${outdir}"
			cmake "${SRC_ROOT}" \
				-G "Unix Makefiles" \
				-C "${CROSS_PRESET}" \
				-DCMAKE_SYSTEM_NAME=Darwin \
				-DCMAKE_CROSSCOMPILING=1 \
				-DCMAKE_OSX_SYSROOT="${sdk_path}" \
				-DCMAKE_OSX_ARCHITECTURES="${arch}" \
				-DCMAKE_OSX_DEPLOYMENT_TARGET="$(platform_min_version "${platform}")" \
				-DCMAKE_C_COMPILER="$(xcrun --sdk "${sdk}" --find clang)" \
				-DCMAKE_INSTALL_PREFIX="${outdir}/install" \
				-DWITH_SSL=OPENSSL \
				-DOPENSSL_ROOT_DIR="${openssl_install}" \
				-DOPENSSL_USE_STATIC_LIBS=TRUE \
				-DWITH_EXTERNAL_ZLIB=ON \
				-DZLIB_LIBRARY="${zlib_install}/lib/libz.a" \
				-DZLIB_INCLUDE_DIR="${zlib_install}/include" \
				-DWITH_CURL=OFF \
				-DWITH_UNIT_TESTS=OFF \
				-DCLIENT_PLUGIN_CACHING_SHA2_PASSWORD=STATIC \
				-DCLIENT_PLUGIN_SHA256_PASSWORD=STATIC \
				-DCLIENT_PLUGIN_DIALOG=OFF \
				-DCLIENT_PLUGIN_CLIENT_ED25519=OFF \
				-DCLIENT_PLUGIN_PARSEC=OFF \
				-DCLIENT_PLUGIN_AUTH_GSSAPI_CLIENT=OFF \
				-DCLIENT_PLUGIN_MYSQL_CLEAR_PASSWORD=OFF \
				-DCLIENT_PLUGIN_ZSTD=OFF > cmake.log 2>&1
			make -j"$(sysctl -n hw.ncpu)" mariadbclient > build.log 2>&1
			make install > install.log 2>&1
		)
		# The DEFAULT layout nests the headers one level down; flatten them so
		# the canonical include root serves <mysql.h> directly.
		cp -R "${outdir}/install/include/mariadb/." "${outdir}/install/include/"
		cp "${outdir}/install/lib/mariadb/libmariadbclient.a" "${outdir}/libmariadbclient.a"
		if [[ "${HEADERS_READY}" == "0" ]]; then
			SRC_HEADERS_DIR="${outdir}/install/include"
			HEADERS_READY=1
		fi
	done
	lipo_platform "${platform}" libmariadbclient.a
	install_headers_from "${platform}"
done

finish_library libmariadbclient.a
