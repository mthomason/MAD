#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  libraries.sh -- builds the C libraries the frameworks link (docs/project/MAD_LINUX.md
#  §7), natively, inside the image.
#
#  Usage:
#    libraries.sh --fetch    download + verify every pinned source
#    libraries.sh --build    build + install them (fetches first)
#
#  The Compressor recipes next door build the same versions for Apple; this is
#  the Linux half of the same idea, and it follows the conventions of
#  lib/toolchain.sh: pins in ../libraries.conf, per-library build knowledge in
#  build_<name> functions, installs under /usr/local.
#
#  sqlite3 is compiled from the released amalgamation with the option list in
#  Compressor/sqlite3.xcconfig, which the image copies in beside this script.
#  That file is the single place the format-deciding flags are written down
#  (docs/project/LIBRARIES.md §4); it is read here, never duplicated.

set -euo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# conf_read/conf_get read whichever conf MADLINUX_CONF names; the libraries
# have their own file, beside toolchain.conf.
export MADLINUX_CONF="${MADLINUX_DIR}/libraries.conf"

WORK="${MADLINUX_LIB_WORK:-/tmp/madlinux-libs}"
JOBS="${MADLINUX_JOBS:-$(nproc)}"
PREFIX="${MADLINUX_LIB_PREFIX:-/usr/local}"
SQLITE3_XCCONFIG="${MADLINUX_SQLITE3_XCCONFIG:-/opt/madlinux/sqlite3.xcconfig}"

source_dir() { # name -> echoes a fresh work tree for the component
	local name="$1" ref archive dest
	ref="$(conf_get "${name}" ref)"
	dest="${WORK}/${name}"
	/bin/rm -rf "${dest}"
	mkdir -p "${dest}"
	if [[ "${ref}" == "-" ]]; then
		archive="$(fetch_archive "$(conf_get "${name}" url)" "$(conf_get "${name}" sha256)")"
		tar -xzf "${archive}" -C "${dest}" --strip-components=1 || die "${name}: extract failed"
	else
		cp -R "$(clone_pinned "${name}" "${ref}" "$(conf_get "${name}" commit)" "$(conf_get "${name}" url)")/." "${dest}"
	fi
	echo "${dest}"
}

# The SQLITE_DEFINES line from Compressor/sqlite3.xcconfig, bare macro names;
# the -D is added here, exactly as the recipe does.
sqlite3_defines() { # -> echoes the defines, space separated
	local defines
	[[ -f "${SQLITE3_XCCONFIG}" ]] || die "missing ${SQLITE3_XCCONFIG}"
	defines="$(sed -n 's/^SQLITE_DEFINES[[:space:]]*=[[:space:]]*//p' "${SQLITE3_XCCONFIG}")"
	[[ -n "${defines}" ]] || die "no SQLITE_DEFINES line in ${SQLITE3_XCCONFIG}"
	echo "${defines}"
}

build_sqlite3() { # src
	local src="$1" defines define
	local cflags=(-O2 -fPIC -DSQLITE_THREADSAFE=1)
	defines="$(sqlite3_defines)"
	for define in ${defines}; do
		cflags+=("-D${define}")
	done

	clang "${cflags[@]}" -c "${src}/sqlite3.c" -o "${src}/sqlite3.o"
	ar rcs "${src}/libsqlite3.a" "${src}/sqlite3.o"

	install -d "${PREFIX}/include" "${PREFIX}/lib"
	install -m 0644 "${src}/sqlite3.h" "${src}/sqlite3ext.h" "${PREFIX}/include/"
	install -m 0644 "${src}/libsqlite3.a" "${PREFIX}/lib/"
	ldconfig
}

build_openssl() { # src
	local src="$1" target
	case "$(uname -m)" in
		aarch64 | arm64) target=linux-aarch64 ;;
		x86_64 | amd64) target=linux-x86_64 ;;
		*) die "openssl: unsupported architecture $(uname -m)" ;;
	esac
	(
		cd "${src}"
		# Static only: the frameworks link the archives, and a shared build
		# would put the image's libssl on a runtime path nothing manages.
		./Configure --prefix="${PREFIX}" --libdir=lib --openssldir="${PREFIX}/ssl" \
			no-shared no-tests "${target}"
		make -j"${JOBS}"
		make install_sw
	)
	ldconfig
}

build_freetds() { # src
	(
		cd "$1"
		# The same option list as Compressor/lib/recipes/freetds.sh, minus the
		# Apple slices: --enable-msdblib is what MADTds's sybdb.h include
		# expects, and apps/server/pool/odbc are none of the frameworks'.
		./configure --prefix="${PREFIX}" \
			--enable-msdblib --disable-apps --disable-server --disable-pool --disable-odbc \
			--with-tdsver=7.4 --with-openssl="${PREFIX}" \
			--enable-static --enable-shared=no \
			--disable-rpath --disable-debug
		make -j"${JOBS}"
		make install
	)
	# The recipe's one edit: freetds' BOOL is an int, which collides with
	# Foundation's.  Apple's sed and GNU sed disagree on -i, hence the
	# spelled-out form here.
	sed -i 's/^typedef int BOOL;$/\/\/typedef int BOOL;/' "${PREFIX}/include/sybdb.h"
	ldconfig
}

build_zlib() { # src
	(
		cd "$1"
		./configure --prefix="${PREFIX}" --static
		make -j"${JOBS}"
		make install
	)
	ldconfig
}

build_bzip2() { # src
	(
		cd "$1"
		# bzip2 has no configure; its Makefile hardcodes gcc (which the image
		# deliberately does not have), takes the prefix, and needs -fPIC for
		# the archive to be linkable into shared objects later.
		make -j"${JOBS}" CC=clang CFLAGS="-O2 -fPIC -Wall"
		make install PREFIX="${PREFIX}"
	)
	ldconfig
}

build_libarchive() { # src
	(
		cd "$1"
		# The frameworks' archive path needs the common formats; openssl not
		# required (libarchive's own crypto is off by default), zlib and bzip2
		# are already installed beside it -- -L/-I point configure at them,
		# since /usr/local is not searched by the compiler driver here.
		# The command-line tools are not built: nothing uses them.
		LDFLAGS="-L${PREFIX}/lib" CPPFLAGS="-I${PREFIX}/include" \
		./configure --prefix="${PREFIX}" --without-xml2 --without-expat \
			--without-lz4 --without-zstd --without-lzma --without-lzo2 \
			--disable-bsdtar --disable-bsdcat --disable-bsdcpio --disable-bsdunzip \
			--enable-static --disable-shared
		make -j"${JOBS}"
		make install
	)
	ldconfig
}

build_mariadb() { # src
	local bld="$1/build-linux"
	mkdir -p "${bld}"
	# The option set mirrors Compressor/lib/recipes/mariadb.sh: the static
	# mariadbclient target (libmariadb is hardcoded shared on UNIX), the
	# openssl built above, external zlib, no curl/tests, and the MySQL 8 auth
	# plugins static while every other plugin is disabled -- no plugin .so
	# exists in the image.  The install dirs are overridden so mysql.h lands
	# in the default include path and the archive where find_library looks.
	(
		cd "${bld}"
		cmake "$1" \
			-DCMAKE_INSTALL_PREFIX="${PREFIX}" \
			-DCMAKE_BUILD_TYPE=Release \
			-DWITH_SSL=OPENSSL \
			-DOPENSSL_ROOT_DIR="${PREFIX}" -DOPENSSL_USE_STATIC_LIBS=TRUE \
			-DWITH_EXTERNAL_ZLIB=ON \
			-DZLIB_LIBRARY="${PREFIX}/lib/libz.a" -DZLIB_INCLUDE_DIR="${PREFIX}/include" \
			-DWITH_CURL=OFF -DWITH_UNIT_TESTS=OFF \
			-DCLIENT_PLUGIN_CACHING_SHA2_PASSWORD=STATIC \
			-DCLIENT_PLUGIN_SHA256_PASSWORD=STATIC \
			-DCLIENT_PLUGIN_DIALOG=OFF \
			-DCLIENT_PLUGIN_CLIENT_ED25519=OFF \
			-DCLIENT_PLUGIN_PARSEC=OFF \
			-DCLIENT_PLUGIN_AUTH_GSSAPI_CLIENT=OFF \
			-DCLIENT_PLUGIN_MYSQL_CLEAR_PASSWORD=OFF \
			-DCLIENT_PLUGIN_ZSTD=OFF \
			-DINSTALL_LIBDIR=lib -DINSTALL_INCLUDEDIR=include
		make -j"${JOBS}" mariadbclient
		make install
	)
	ldconfig
}

fetch_all() {
	require_cmd curl git tar
	conf_read
	local name
	for name in "${CONF_NAMES[@]}"; do
		if [[ "$(conf_get "${name}" ref)" == "-" ]]; then
			fetch_archive "$(conf_get "${name}" url)" "$(conf_get "${name}" sha256)" >/dev/null
		else
			clone_pinned "${name}" "$(conf_get "${name}" ref)" "$(conf_get "${name}" commit)" "$(conf_get "${name}" url)" >/dev/null
		fi
	done
	log "library sources verified: ${CONF_NAMES[*]}"
}

build_all() {
	fetch_all
	conf_read
	require_cmd ar clang make
	local name
	for name in "${CONF_NAMES[@]}"; do
		log "build ${name} $(conf_get "${name}" version)"
		"build_${name}" "$(source_dir "${name}")"
	done
	echo "OK libraries: ${CONF_NAMES[*]}"
}

case "${1:-}" in
	--fetch) fetch_all ;;
	--build) build_all ;;
	-h | --help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//' ;;
	*) die "usage: libraries.sh --fetch | --build" ;;
esac
