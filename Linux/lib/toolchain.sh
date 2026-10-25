#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  toolchain.sh -- builds the Linux toolchain inside the image (Phase B).
#
#  Usage:
#    toolchain.sh --fetch    download + verify every pinned source
#    toolchain.sh --build    build + install them (fetches first)
#
#  Components and order follow GNUstep's Linux guide: libobjc2, libdispatch,
#  gnustep-make, gnustep-base.  The compiler is the distro clang (Ubuntu 24.04
#  -> clang 18); everything installs under /usr/local.
#
#  Per-component build knowledge lives here, the way Compressor recipes carry
#  it: a version bump means re-checking that component's function.  The pins
#  are in ../toolchain.conf.

set -euo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

WORK="${MADLINUX_WORK:-/tmp/madlinux-build}"
JOBS="${MADLINUX_JOBS:-$(nproc)}"

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

build_libobjc2() { # src
	local src="$1" bld="$1/build-linux"
	mkdir -p "${bld}"
	cmake -S "${src}" -B "${bld}" -DCMAKE_BUILD_TYPE=RelWithDebInfo
	cmake --build "${bld}" -j"${JOBS}"
	cmake --install "${bld}"
}

build_libdispatch() { # src
	local src="$1" bld="$1/build-linux"
	mkdir -p "${bld}"
	# Dispatch objects are plain C structs on GNUstep, not Objective-C objects:
	# the library's internal.h pins OS_OBJECT_HAVE_OBJC_SUPPORT to 0 with
	# -Werror, so consumers cannot opt in either.  MADExclusivityController's
	# queue description is guarded in the source for the same reason.
	cmake -S "${src}" -B "${bld}" \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DINSTALL_PRIVATE_HEADERS=YES \
		-DBUILD_TESTING=OFF \
		-DCMAKE_C_COMPILER=clang \
		-DCMAKE_CXX_COMPILER=clang++
	cmake --build "${bld}" -j"${JOBS}"
	cmake --install "${bld}"
}

build_gnustep_make() { # src
	(
		cd "$1"
		./configure --prefix=/usr/local --with-layout=fhs \
			--with-library-combo=ng-gnu-gnu \
			--enable-native-objc-exceptions \
			--enable-objc-arc \
			--enable-install-ld-so-conf \
			--enable-debug-by-default
		make install
	)
}

build_gnustep_base() { # src
	(
		set +u # GNUstep.sh reads variables it has not set
		. /usr/local/share/GNUstep/Makefiles/GNUstep.sh
		cd "$1"
		./configure
		make -j"${JOBS}"
		make install
	)
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
	log "sources verified: ${CONF_NAMES[*]}"
}

build_all() {
	fetch_all
	conf_read
	require_cmd cmake make clang
	local name
	for name in "${CONF_NAMES[@]}"; do
		log "build ${name} $(conf_get "${name}" version)"
		"build_${name}" "$(source_dir "${name}")"
		ldconfig
	done
	echo "OK toolchain: libobjc2 $(conf_get libobjc2 version), libdispatch $(conf_get libdispatch version), gnustep_make $(conf_get gnustep_make version), gnustep_base $(conf_get gnustep_base version)"
}

case "${1:-}" in
	--fetch) fetch_all ;;
	--build) build_all ;;
	-h | --help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//' ;;
	*) die "usage: toolchain.sh --fetch | --build" ;;
esac
