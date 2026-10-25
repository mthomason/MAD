#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  Recipe for sqlite3.  Generates the amalgamation on the host, then compiles
#  it once per slice into libsqlite3.a with the option list from
#  Compressor/sqlite3.xcconfig -- the single place the SQLite compile-time
#  options are written down.  They were once written in two places (this
#  script and the MADSqlite3 target) and silently disagreed, so the engine
#  writing every .maddb cache was configured by accident.  Now the recipe is
#  the only consumer.  See docs/project/LIBRARIES.md section 4 and docs/project/BUGS.md (hazard H7).

set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

XCCONFIG="${COMPRESSOR_DIR}/sqlite3.xcconfig"
[[ -f "${XCCONFIG}" ]] || die "sqlite3.xcconfig not found"

# The file holds bare macro names (Xcode adds -D itself); add it back here.
SQLITE_DEFINES="$(sed -n 's/^SQLITE_DEFINES[[:space:]]*=[[:space:]]*//p' "${XCCONFIG}")"
[[ -n "${SQLITE_DEFINES}" ]] || die "no SQLITE_DEFINES line in ${XCCONFIG}"

# Same warning suppressions the MADSqlite3 target applied to the amalgamation,
# so the baseline binary matches what the framework has always compiled.
SQLITE_CFLAGS=(
	-Os
	-Wno-ambiguous-macro -Wno-\#warnings -Wno-unreachable-code
	-Wno-sign-conversion -Wno-shorten-64-to-32 -Wno-implicit-int
	-Wno-pointer-sign -Wno-comma
)
for define in ${SQLITE_DEFINES}; do
	SQLITE_CFLAGS+=("-D${define}")
done

MANIFEST_FLAGS="defines: ${SQLITE_DEFINES}; opt: -Os"

fetch_source "${URL}" "${SHA256}"

# Amalgamation generation is platform-independent; run it once on the host.
# TCL must stay enabled: the Makefile regenerates opcodes.h from vdbe.c
# through the bundled jimsh, and since 3.50 the checked-in opcodes files
# in the source zip are stale (vdbe.c references opcodes they do not
# define), so --disable-tcl produces an amalgamation that cannot compile.
AMALG_DIR="${BUILD_DIR}/${LIB}/amalgamation"
mkdir -p "${AMALG_DIR}"
# Zip extraction leaves the generated files (opcodes.h, parse.h) with
# mtimes newer than their inputs, so make would skip regenerating them --
# and the checked-in copies can be stale (3.53.3's opcodes.h predates its
# vdbe.c).  Touching the inputs forces the regeneration the release's own
# amalgamation was built with.
touch "${SRC_ROOT}/src/vdbe.c" "${SRC_ROOT}/src/parse.y"
(
	cd "${AMALG_DIR}"
	"${SRC_ROOT}/configure" >/dev/null
	make sqlite3.c >/dev/null
)
[[ -f "${AMALG_DIR}/sqlite3.c" && -f "${AMALG_DIR}/sqlite3.h" ]] \
	|| die "amalgamation generation failed"

HEADERS_DIR="${BUILD_DIR}/${LIB}/headers"
mkdir -p "${HEADERS_DIR}"
cp "${AMALG_DIR}/sqlite3.h" "${AMALG_DIR}/sqlite3ext.h" "${HEADERS_DIR}/"
SRC_HEADERS_DIR="${HEADERS_DIR}"

for platform in ${PLATFORMS}; do
	for arch in $(platform_archs "${platform}"); do
		outdir="$(arch_build_dir "${platform}" "${arch}")"
		mkdir -p "${outdir}"
		xcrun --sdk "$(platform_sdk "${platform}")" clang -c "${AMALG_DIR}/sqlite3.c" \
			-o "${outdir}/sqlite3.o" \
			$(arch_cflags "${platform}" "${arch}") \
			"${SQLITE_CFLAGS[@]}"
		xcrun ar rcs "${outdir}/libsqlite3.a" "${outdir}/sqlite3.o"
	done
	lipo_platform "${platform}" libsqlite3.a
	install_headers_from "${platform}"
done

finish_library libsqlite3.a
