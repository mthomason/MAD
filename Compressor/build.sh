#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  build.sh -- the Compressor driver.
#
#  One entry point for every third-party library.  It reads matrix.conf,
#  orders dependencies, and runs the per-library recipes under
#  lib/recipes/<lib>.sh.  Artifacts land in:
#
#    library/<lib>.xcframework   the single artifact Xcode links
#    library/<lib>/include       the canonical header dir consumers name
#    library/manifests/<lib>.json  version, source hash, flags, slice SHAs
#
#  Usage:
#    build.sh <lib>...           ensure each (deps first); no-op when fresh
#    build.sh --all              ensure every library in matrix.conf
#    build.sh --rebuild <lib>... ignore manifests and rebuild
#    build.sh --verify [lib]...  check artifacts against matrix.conf + manifests
#    build.sh --platforms ios,simulator,macosx   limit platforms (default: all)
#
#  Xcode calls this in ensure mode from the run-script phases of the targets
#  that consume libraries.  It is fast when fresh and builds only what is
#  missing.  See docs/project/DEVELOPER.md and docs/project/LIBRARIES.md.
#
#  Runs on the system bash (3.2 on macOS): no associative arrays, no
#  mapfile, no ${var,,} -- matrix values live in prefixed variables.

set -euo pipefail

COMPRESSOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${COMPRESSOR_DIR}/lib/common.sh"

MATRIX_FILE="${COMPRESSOR_DIR}/matrix.conf"

ALL=0
REBUILD=0
MODE=ensure
PLATFORMS="ios simulator macosx"
LIBS=()

usage() {
	sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--all) ALL=1 ;;
			--rebuild) REBUILD=1 ;;
			--verify) MODE=verify ;;
			--platforms)
				shift
				PLATFORMS="${1//,/ }"
				;;
			-h | --help) usage; exit 0 ;;
			-*) die "unknown option: $1 (try --help)" ;;
			*) LIBS+=("$1") ;;
		esac
		shift
	done

	for p in ${PLATFORMS}; do
		case "${p}" in
			ios | simulator | macosx) ;;
			*) die "unknown platform: ${p}" ;;
		esac
	done

	if [[ "${ALL}" == "0" && ${#LIBS[@]} == 0 ]]; then
		usage
		exit 1
	fi
}

MATRIX_ORDER=()

matrix_set() { # lib field value
	printf -v "MATRIX_${2}_${1}" "%s" "$3"
}

matrix_get() { # lib field -> echoes the value (empty when unset)
	local key="MATRIX_${2}_${1}"
	echo "${!key:-}"
}

read_matrix() {
	local lib version sha url ios sim mac minios minmac deps
	while read -r lib version sha url ios sim mac minios minmac deps; do
		[[ "${lib}" == "lib" ]] && continue # the header row
		MATRIX_ORDER+=("${lib}")
		matrix_set "${lib}" version "${version}"
		matrix_set "${lib}" sha "${sha}"
		matrix_set "${lib}" url "${url}"
		matrix_set "${lib}" ios "${ios}"
		matrix_set "${lib}" sim "${sim}"
		matrix_set "${lib}" mac "${mac}"
		matrix_set "${lib}" minios "${minios}"
		matrix_set "${lib}" minmac "${minmac}"
		matrix_set "${lib}" deps "${deps}"
	done < <(grep -v '^#' "${MATRIX_FILE}" | grep -v '^[[:space:]]*$' || true)
}

export_lib_env() {
	local lib="$1"
	export LIB="${lib}"
	export VERSION="$(matrix_get "${lib}" version)"
	export SHA256="$(matrix_get "${lib}" sha)"
	export URL="$(matrix_get "${lib}" url)"
	export MIN_IOS="$(matrix_get "${lib}" minios)"
	export MIN_MAC="$(matrix_get "${lib}" minmac)"

	# Comma-separated in the matrix; recipes want space-separated.
	ARCHS_IOS="$(matrix_get "${lib}" ios)"; ARCHS_IOS="${ARCHS_IOS//,/ }"; export ARCHS_IOS
	ARCHS_SIM="$(matrix_get "${lib}" sim)"; ARCHS_SIM="${ARCHS_SIM//,/ }"; export ARCHS_SIM
	ARCHS_MAC="$(matrix_get "${lib}" mac)"; ARCHS_MAC="${ARCHS_MAC//,/ }"; export ARCHS_MAC
}

# Dependency-ordered closure of the requested libraries.
ORDER=()

visit_lib() {
	local lib="$1" dep visiting_key dep_key visited_key
	[[ -n "$(matrix_get "${lib}" version)" ]] || die "unknown library: ${lib}"
	visiting_key="VISITING_${lib}"
	[[ -n "${!visiting_key:-}" ]] && die "dependency cycle at ${lib}"
	printf -v "${visiting_key}" "1"
	for dep in $(matrix_get "${lib}" deps | tr ',' ' '); do
		[[ "${dep}" == "-" ]] && continue
		dep_key="VISITED_${dep}"
		[[ -n "${!dep_key:-}" ]] && continue
		visit_lib "${dep}"
	done
	unset "${visiting_key}"
	visited_key="VISITED_${lib}"
	if [[ -z "${!visited_key:-}" ]]; then
		printf -v "${visited_key}" "1"
		ORDER+=("${lib}")
	fi
}

resolve_order() {
	local lib
	for lib in "$@"; do
		visit_lib "${lib}"
	done
}

is_fresh() {
	local lib="$1" manifest p
	manifest="${MANIFEST_DIR}/${lib}.json"
	[[ -f "${manifest}" ]] || return 1
	[[ "$(plutil -extract version raw "${manifest}" 2>/dev/null || true)" == "$(matrix_get "${lib}" version)" ]] || return 1
	[[ "$(plutil -extract source.sha256 raw "${manifest}" 2>/dev/null || true)" == "$(matrix_get "${lib}" sha)" ]] || return 1
	[[ -d "${LIBRARY_DIR}/${lib}.xcframework" ]] || return 1
	[[ -d "${LIBRARY_DIR}/${lib}/include" ]] || return 1
	for p in ${PLATFORMS}; do
		[[ -n "$(plutil -extract "slices.${p}.sha256" raw "${manifest}" 2>/dev/null || true)" ]] || return 1
	done
	return 0
}

build_lib() {
	local lib="$1"
	export_lib_env "${lib}"

	# --rebuild forces only the named libraries; dependencies get the
	# normal fresh check, so iterating on one recipe does not rebuild its
	# whole dependency chain every time.
	local force=0 explicit_key="EXPLICIT_${lib}"
	[[ "${REBUILD}" == "1" && -n "${!explicit_key:-}" ]] && force=1

	if [[ "${force}" == "0" ]] && is_fresh "${lib}"; then
		log "${lib} $(matrix_get "${lib}" version) is fresh"
		return 0
	fi

	if [[ ! -x "${COMPRESSOR_DIR}/lib/recipes/${lib}.sh" ]]; then
		die "no recipe for ${lib} (expected lib/recipes/${lib}.sh)"
	fi

	export PLATFORMS
	# Note: this function is called under `|| { …; }` in main(), which
	# disables set -e for everything inside it -- so failures must be made
	# loud here by hand, not left to the shell.
	bash "${COMPRESSOR_DIR}/lib/recipes/${lib}.sh" \
		|| { echo "FAIL ${lib}: recipe exited $?"; return 1; }

	if [[ "$(matrix_get "${lib}" sha)" == "-" ]]; then
		log "NOTE: sha256 for ${lib} is unpinned; pin the hash from the log above in matrix.conf"
	fi
}

# Portable build lock (flock is not on macOS).  Serializes the bootstrap when
# several Xcode targets run ensure phases in parallel.  A lock whose owner is
# dead, or that is older than 12 hours, is broken.
LOCK_DIR="${BUILD_DIR}/.ensure.lock.d"

acquire_lock() {
	mkdir -p "${BUILD_DIR}"
	while true; do
		if mkdir "${LOCK_DIR}" 2>/dev/null; then
			echo $$ > "${LOCK_DIR}/pid"
			trap 'release_lock; exit 1' INT TERM
			trap release_lock EXIT
			return 0
		fi
		if [[ -f "${LOCK_DIR}/pid" ]]; then
			local owner
			owner="$(cat "${LOCK_DIR}/pid")"
			if ! kill -0 "${owner}" 2>/dev/null; then
				log "breaking stale lock held by dead pid ${owner}"
				rm -rf "${LOCK_DIR}"
				continue
			fi
		fi
		sleep 1
	done
}

release_lock() {
	rm -rf "${LOCK_DIR}"
}

verify_lib() {
	local lib="$1" manifest slice platform failures=0
	export_lib_env "${lib}"
	manifest="${MANIFEST_DIR}/${lib}.json"

	[[ -f "${manifest}" ]] || { echo "FAIL ${lib}: no manifest"; return 1; }
	[[ "$(plutil -extract version raw "${manifest}" 2>/dev/null || true)" == "$(matrix_get "${lib}" version)" ]] \
		|| { echo "FAIL ${lib}: manifest version mismatch"; failures=1; }
	[[ "$(plutil -extract source.sha256 raw "${manifest}" 2>/dev/null || true)" == "$(matrix_get "${lib}" sha)" ]] \
		|| { echo "FAIL ${lib}: source sha256 mismatch"; failures=1; }
	[[ -d "${LIBRARY_DIR}/${lib}/include" && -n "$(ls -A "${LIBRARY_DIR}/${lib}/include")" ]] \
		|| { echo "FAIL ${lib}: include dir missing"; failures=1; }

	local xcfw="${LIBRARY_DIR}/${lib}.xcframework"
	[[ -d "${xcfw}" ]] || { echo "FAIL ${lib}: no xcframework"; return 1; }

	# lipo -archs prints in its own order, so compare sorted sets.
	local expected archs libfile found
	for platform in ${PLATFORMS}; do
		expected="$(platform_archs "${platform}" | tr ' ' '\n' | sort | tr '\n' ',')"
		found=0
		for slice in "${xcfw}"/*/; do
			[[ "$(slice_platform "$(basename "${slice}")")" == "${platform}" ]] || continue
			libfile="$(ls "${slice}"/lib*.a 2>/dev/null | head -1)"
			[[ -n "${libfile}" ]] || continue
			archs="$(xcrun lipo -archs "${libfile}" | tr ' ' '\n' | sort | tr '\n' ',')"
			[[ "${archs}" == "${expected}" ]] \
				|| { echo "FAIL ${lib}: ${platform} slice archs ${archs}, expected ${expected}"; failures=1; }
			found=1
			break
		done
		[[ "${found}" == "1" ]] || { echo "FAIL ${lib}: no ${platform} slice"; failures=1; }
	done

	# Optional per-library checks (version strings, feature flags).  Sourced
	# first so they can set SKIP_VERSION_STRING for libraries whose version
	# is not embedded in the archive (zint's ZINT_VERSION macro is only used
	# by its frontend).
	local skip_version_string=0
	if [[ -f "${COMPRESSOR_DIR}/lib/verify/${lib}.sh" ]]; then
		export PLATFORMS
		# shellcheck source=/dev/null
		. "${COMPRESSOR_DIR}/lib/verify/${lib}.sh" || { echo "FAIL ${lib}: extra checks failed"; failures=1; }
		skip_version_string="${SKIP_VERSION_STRING:-0}"
	fi

	# Every library embeds its version string somewhere; check it against
	# the matrix row.
	local first_lib version_count
	first_lib="$(ls "${xcfw}"/*/lib*.a 2>/dev/null | head -1)"
	if [[ -n "${first_lib}" ]]; then
		version_count="$(strings "${first_lib}" | grep -c "$(matrix_get "${lib}" version)" || true)"
		if [[ "${skip_version_string}" != "1" && "${version_count}" -lt 1 ]]; then
			echo "FAIL ${lib}: version string $(matrix_get "${lib}" version) missing"
			failures=1
		fi
	else
		echo "FAIL ${lib}: no library in ${xcfw}"
		failures=1
	fi

	[[ "${failures}" == "0" ]] && echo "OK ${lib} $(matrix_get "${lib}" version)"
	return "${failures}"
}

main() {
	parse_args "$@"
	read_matrix

	if [[ "${ALL}" == "1" ]]; then
		LIBS=("${MATRIX_ORDER[@]}")
	fi

	if [[ "${MODE}" == "verify" ]]; then
		local lib failures=0
		for lib in "${LIBS[@]}"; do
			verify_lib "${lib}" || failures=1
		done
		exit "${failures}"
	fi

	acquire_lock
	local lib failures=0
	for lib in "${LIBS[@]}"; do
		printf -v "EXPLICIT_${lib}" "1"
	done
	resolve_order "${LIBS[@]}"
	for lib in "${ORDER[@]}"; do
		build_lib "${lib}" || { echo "FAIL ${lib}"; failures=1; }
	done
	release_lock
	exit "${failures}"
}

main "$@"
