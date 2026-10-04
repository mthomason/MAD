#!/bin/bash
#
#  Recipe for mysqlclient.  The hard one: mysql's build runs host executables
#  (comp_err via GenError/GenClientError, uca9dump via the strings library)
#  to generate headers and sources that are platform-independent.  So:
#
#    Stage A -- one native macosx-arm64 build produces the generated files
#      (and proves they exist before any cross build starts).
#    Stage B -- each platform/arch cross-configure seeds its build dir with
#      those files.  Make then rebuilds the tool *targets* for iOS -- which
#      is harmless work -- but never runs them, because their outputs are
#      already fresh.
#
#  mysql's own cmake merges clientlib+mytime+strings+vio+mysys+zlib+zstd
#  (WITH_ZLIB=WITH_ZSTD=bundled) into one self-contained libmysqlclient.a,
#  matching what the legacy artifact shipped.

set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

MANIFEST_FLAGS="cmake: WITHOUT_SERVER=ON BUILD_SHARED_LIBS=OFF WITH_ZLIB/ZSTD=bundled WITH_UNIT_TESTS=OFF WITH_SASL=OFF WITH_LDAP=OFF; boost: bundled; tools: native macosx-arm64 stage"

fetch_source "${URL}" "${SHA256}"

# 8.4 bundles boost inside the source tree (extra/boost/boost_1_84_0) and
# its cmake uses it unconditionally -- there is no WITH_BOOST to point.
BOOST_DIR="${SRC_ROOT}/extra/boost/boost_1_84_0"
[[ -d "${BOOST_DIR}/boost" ]] || die "no bundled boost in source (expected extra/boost/boost_1_84_0)"

NATIVE="${BUILD_DIR}/${LIB}/native"
NATIVE_OPENSSL="${BUILD_DIR}/openssl/macosx/install"

# Cross-compiling preset: cmake refuses unseeded try_run() probes in cross
# mode, which is what we want -- every run-based configure check below is
# answered explicitly with the value iOS actually has, and any probe a
# future mysql version adds will fail loudly instead of guessing.
CROSS_PRESET="${BUILD_DIR}/${LIB}/cross-preset.cmake"
cat > "${CROSS_PRESET}" <<'EOF'
set(HAVE_SUPPORTED_CLANG_VERSION_EXITCODE "0" CACHE STRING "")
set(HAVE_SUPPORTED_CLANG_VERSION_EXITCODE__TRYRUN_OUTPUT "" CACHE STRING "")
set(HAVE_CLOCK_GETTIME_EXITCODE "0" CACHE STRING "")
set(HAVE_CLOCK_GETTIME_EXITCODE__TRYRUN_OUTPUT "" CACHE STRING "")
set(HAVE_CLOCK_REALTIME_EXITCODE "0" CACHE STRING "")
set(HAVE_CLOCK_REALTIME_EXITCODE__TRYRUN_OUTPUT "" CACHE STRING "")
# 8.0 bundled libevent and its TRY_RUN version probe needed the
# TEST_RUN_RESULT seeds below; 8.4 dropped libevent entirely, so any
# new run-based probe a future version adds will fail loudly here.
EOF

# --- Stage A: native host tools + generated files (macosx arm64) ---
if [[ ! -f "${NATIVE}/include/mysqld_error.h" ]]; then
	# The native stage needs a macOS openssl slice; build it inline if this
	# run's platforms did not.  The child gets the openssl matrix row, not
	# this recipe's environment, and finish_library preserves the other
	# slices, so this does not disturb them.
	if [[ ! -d "${NATIVE_OPENSSL}/lib" ]]; then
		log "building the openssl macosx slice for the native stage"
		row="$(grep -E '^openssl[[:space:]]' "${COMPRESSOR_DIR}/matrix.conf" | head -1)"
		[[ -n "${row}" ]] || die "no openssl row in matrix.conf"
		read -r _ v sha url ios sim mac minios minmac _ <<< "${row}"
		LIB=openssl VERSION="${v}" SHA256="${sha}" URL="${url}" \
			ARCHS_IOS="${ios//,/ }" ARCHS_SIM="${sim//,/ }" ARCHS_MAC="${mac//,/ }" \
			MIN_IOS="${minios}" MIN_MAC="${minmac}" PLATFORMS=macosx \
			bash "${COMPRESSOR_DIR}/lib/recipes/openssl.sh"
	fi
	[[ -d "${NATIVE_OPENSSL}/lib" ]] || die "openssl macosx install missing"
	log "stage A: native tools build (${NATIVE})"
	rm -rf "${NATIVE}"
	mkdir -p "${NATIVE}"
	(
		cd "${NATIVE}"
		cmake "${SRC_ROOT}" \
			-G "Unix Makefiles" \
			-DWITHOUT_SERVER=ON \
			-DBUILD_SHARED_LIBS=OFF \
			-DOPENSSL_ROOT_DIR="${NATIVE_OPENSSL}" \
			-DOPENSSL_INCLUDE_DIR="${NATIVE_OPENSSL}/include" \
			-DOPENSSL_CRYPTO_LIBRARY="${NATIVE_OPENSSL}/lib/libcrypto.a" \
			-DOPENSSL_SSL_LIBRARY="${NATIVE_OPENSSL}/lib/libssl.a" \
			-DWITH_ZLIB=bundled \
			-DWITH_ZSTD=bundled \
			-DWITH_UNIT_TESTS=OFF \
			-DWITH_SASL=OFF \
			-DWITH_LDAP=OFF \
			-DWITH_SSL=system > cmake.log 2>&1
		cmake --build . --target strings GenError GenClientError -j"$(sysctl -n hw.ncpu)" > build.log 2>&1
	)
	[[ -f "${NATIVE}/include/mysqld_error.h" ]] || die "stage A: generated headers missing"
fi

# Point the host-tool custom commands at the native-stage executables.
# Make rebuilds the cross-built tool targets (harmless) and then runs these
# commands -- the native binaries regenerate byte-identical files, where the
# cross-built ones could never run on the host.
sed -i '' "s|COMMAND uca9dump|COMMAND ${NATIVE}/runtime_output_directory/uca9dump|g" \
	"${SRC_ROOT}/strings/CMakeLists.txt"
sed -i '' "s|COMMAND comp_err |COMMAND ${NATIVE}/runtime_output_directory/comp_err |g" \
	"${SRC_ROOT}/utilities/CMakeLists.txt"
sed -i '' "s|COMMAND comp_client_err |COMMAND ${NATIVE}/runtime_output_directory/comp_client_err |g" \
	"${SRC_ROOT}/utilities/CMakeLists.txt"

# --- Stage B: cross builds, seeded from the native stage ---
HEADERS_READY=0
for platform in ${PLATFORMS}; do
	sdk="$(platform_sdk "${platform}")"
	sdk_path="$(xcrun --sdk "${sdk}" --show-sdk-path)"
	openssl_install="${BUILD_DIR}/openssl/${platform}/install"
	[[ -d "${openssl_install}/lib" ]] || die "openssl ${platform} install missing -- build openssl first"
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
				-DCMAKE_CXX_COMPILER="$(xcrun --sdk "${sdk}" --find clang++)" \
				-DWITHOUT_SERVER=ON \
				-DBUILD_SHARED_LIBS=OFF \
				-DOPENSSL_ROOT_DIR="${openssl_install}" \
				-DOPENSSL_INCLUDE_DIR="${openssl_install}/include" \
				-DOPENSSL_CRYPTO_LIBRARY="${openssl_install}/lib/libcrypto.a" \
				-DOPENSSL_SSL_LIBRARY="${openssl_install}/lib/libssl.a" \
				-DWITH_SSL=system \
				-DWITH_ZLIB=bundled \
				-DWITH_ZSTD=bundled \
				-DWITH_UNIT_TESTS=OFF \
				-DWITH_SASL=OFF \
				-DWITH_LDAP=OFF \
				-DCURSES_INCLUDE_PATH="$(xcrun --sdk macosx --show-sdk-path)/usr/include" \
				-DCURSES_LIBRARY="$(xcrun --sdk macosx --show-sdk-path)/usr/lib/libncurses.tbd" > cmake.log 2>&1

			# Seed the generated files from the native stage so make never
			# runs the cross-built tools.
			cp "${NATIVE}"/include/mysqld_error.h \
				"${NATIVE}"/include/mysqld_ername.h \
				"${NATIVE}"/include/mysqld_errmsg.h \
				"${NATIVE}"/include/mysqlclient_ername.h \
				"${outdir}"/include/
			mkdir -p "${outdir}/share/english"
			cp "${NATIVE}"/share/english/errmsg.sys "${outdir}/share/english/" \
				|| cp "$(find "${NATIVE}" -name errmsg.sys | head -1)" "${outdir}/share/english/"
			mkdir -p "${outdir}/strings"
			cp "${NATIVE}"/strings/uca900_zh_tbls.cc "${NATIVE}"/strings/uca900_ja_tbls.cc "${outdir}/strings/"

			cmake --build . --target mysqlclient -j"$(sysctl -n hw.ncpu)" > build.log 2>&1
		)
		cp "$(find "${outdir}" -name libmysqlclient.a | head -1)" "${outdir}/libmysqlclient.a"
		if [[ "${HEADERS_READY}" == "0" ]]; then
			# outdir/include already holds the generated headers (my_config.h,
			# mysql_version.h, the seeded mysqld_*.h); add the source headers.
			cp "${SRC_ROOT}"/include/*.h "${outdir}/include/"
			cp -R "${SRC_ROOT}"/include/mysql "${outdir}/include/"
			SRC_HEADERS_DIR="${outdir}/include"
			HEADERS_READY=1
		fi
	done
	lipo_platform "${platform}" libmysqlclient.a
	install_headers_from "${platform}"
done

finish_library libmysqlclient.a
