#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  common.sh -- helpers shared by the Linux build scripts (Phase B).
#
#  Sourced by lib/toolchain.sh (inside the image) and build.sh (the host
#  driver).  The Compressor helpers next door are macOS-specific; this is the
#  small Linux half of the same idea, and follows the same conventions:
#  log()/die(), one job per function, tabs, bash 3.2-safe (no associative
#  arrays, no mapfile, no ${var,,}).
#
#  The toolchain pins live in toolchain.conf; read them through conf_read and
#  conf_get rather than grepping the file.

MADLINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { # message...
	echo "[${MAD_LOG_TAG:-linux}] $*"
}

die() { # message...
	echo "error: $*" >&2
	exit 1
}

require_cmd() { # command...
	local cmd
	for cmd in "$@"; do
		command -v "${cmd}" >/dev/null 2>&1 || die "required command not found: ${cmd}"
	done
}

sha256_file() { # file -> echoes the hex digest
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$1" | awk '{print $1}'
	else
		shasum -a 256 "$1" | awk '{print $1}'
	fi
}

conf_path() { # -> echoes the toolchain.conf path
	echo "${MADLINUX_CONF:-${MADLINUX_DIR}/toolchain.conf}"
}

CONF_NAMES=()

conf_read() { # -> fills CONF_NAMES and the CONF_<name>_<field> variables
	local file name version ref commit sha url
	file="$(conf_path)"
	[[ -f "${file}" ]] || die "missing toolchain.conf at ${file}"
	CONF_NAMES=()
	while read -r name version ref commit sha url; do
		[[ "${name}" == "name" ]] && continue # the header row
		CONF_NAMES+=("${name}")
		printf -v "CONF_${name}_version" "%s" "${version}"
		printf -v "CONF_${name}_ref" "%s" "${ref}"
		printf -v "CONF_${name}_commit" "%s" "${commit}"
		printf -v "CONF_${name}_sha256" "%s" "${sha}"
		printf -v "CONF_${name}_url" "%s" "${url}"
	done < <(grep -v '^#' "${file}" | grep -v '^[[:space:]]*$' || true)
}

conf_get() { # name field -> echoes the value (empty when unset)
	local key="CONF_${1}_${2}"
	echo "${!key:-}"
}

cache_dir() { # -> echoes the download cache
	echo "${MADLINUX_CACHE:-/var/cache/madlinux}"
}

fetch_archive() { # url sha256 -> echoes the path of the verified archive
	local url="$1" sha="$2"
	local dir file got
	dir="$(cache_dir)"
	file="${dir}/$(basename "${url}")"
	mkdir -p "${dir}"
	if [[ -f "${file}" ]]; then
		[[ "$(sha256_file "${file}")" == "${sha}" ]] && { echo "${file}"; return 0; }
		log "discarding ${file}: hash changed"
		/bin/rm -f "${file}"
	fi
	log "fetch $(basename "${url}")"
	curl -fsSL --retry 3 --retry-delay 2 -o "${file}.part" "${url}" || die "download failed: ${url}"
	got="$(sha256_file "${file}.part")"
	[[ "${got}" == "${sha}" ]] || die "sha256 mismatch for ${url}: got ${got}, want ${sha}"
	mv "${file}.part" "${file}"
	echo "${file}"
}

clone_pinned() { # name ref commit url -> echoes the checkout path (at commit)
	local name="$1" ref="$2" commit="$3" url="$4"
	local dir head
	dir="$(cache_dir)/${name}"
	mkdir -p "$(cache_dir)"
	if [[ ! -d "${dir}" ]]; then
		log "clone ${name} ${ref}"
		git clone --quiet --recurse-submodules --branch "${ref}" "${url}" "${dir}" || die "clone failed: ${url}"
	fi
	git -C "${dir}" checkout --quiet "${commit}" || die "${name}: commit ${commit} is not in ${ref}"
	git -C "${dir}" submodule update --init --recursive --quiet || die "${name}: submodule update failed"
	head="$(git -C "${dir}" rev-parse HEAD)"
	[[ "${head}" == "${commit}" ]] || die "${name}: HEAD ${head} does not match pinned ${commit}"
	echo "${dir}"
}
