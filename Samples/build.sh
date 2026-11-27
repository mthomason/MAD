#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  Samples/build.sh -- build and run the sample-report maker on the Mac.
#
#  The maker links the frameworks the macOS app already built, so run
#  ./Mac/build.sh (or ./Mac/build.sh --no-frameworks after a full build) first.
#
#  Usage:
#    ./Samples/build.sh                 build the maker
#    ./Samples/build.sh --run [args…]   build, then run it with the arguments
#
#  The default output is Samples/Reports, and the source database is the
#  chinook.sqlite3 in the app's asset catalog.  Set MAD_PG_SAMPLE_* and pass
#  `postgres` as the last maker argument to also write the PostgreSQL sample.
#  Set MAD_MYSQL_SAMPLE_*, MAD_PG_SAMPLE_* and MAD_TDS_SAMPLE_* and pass
#  `crossdatabase` to build the three-source composition sample (a driver whose
#  password is unset or unreachable is dropped; two sources are the minimum).
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly BUILD_DIR="${SCRIPT_DIR}/build"
readonly OUTPUT="${BUILD_DIR}/mad-sample-maker"
readonly APP_FRAMEWORKS="${REPO_ROOT}/Mac/build/MAD Designer.app/Contents/Frameworks"

readonly FRAMEWORKS=(
	MADFoundation
	MADDataStructures
	MADCocoaExtensions
	MADFileManager
	MADAPI
	MADSqlite3
	MADTds
	MADTdsClient
	MADMySQL
	MADPostgres
	MADBarcodes
	MAD
)

if [[ ! -d "${APP_FRAMEWORKS}" ]]; then
	echo "Missing ${APP_FRAMEWORKS}." >&2
	echo "Run ./Mac/build.sh first." >&2
	exit 1
fi

mkdir -p "${BUILD_DIR}"

framework_flags() {
	local framework
	for framework in "${FRAMEWORKS[@]}"; do
		printf -- '-framework %s ' "${framework}"
	done
}

echo "Compiling mad-sample-maker..."
# shellcheck disable=SC2046
xcrun --sdk macosx clang \
	-fobjc-arc \
	-g -O0 \
	-target arm64-apple-macos12.0 \
	-F "${APP_FRAMEWORKS}" \
	$(framework_flags) \
	-framework Cocoa \
	-framework CoreData \
	-framework Quartz \
	-framework WebKit \
	-framework UniformTypeIdentifiers \
	-Wl,-rpath,"${APP_FRAMEWORKS}" \
	"${SCRIPT_DIR}/Tools/MADSampleMaker.m" \
	-o "${OUTPUT}"

codesign --force --sign - "${OUTPUT}"

if [[ "${1:-}" == "--run" ]]; then
	shift
	if [[ $# -eq 0 ]]; then
		set -- "${SCRIPT_DIR}/Reports" \
			   "${REPO_ROOT}/MADDesigner/Resources/Assets/Samples.xcassets/Data/chinook.dataset/chinook.sqlite3"
	fi
	exec "${OUTPUT}" "$@"
fi

echo "Built ${OUTPUT}"
echo "Run: ${OUTPUT} <output-directory> <chinook.sqlite3> [postgres]"
