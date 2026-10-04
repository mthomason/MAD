#!/bin/bash
#
#  common.sh -- helpers shared by Compressor/build.sh and lib/recipes/<lib>.sh.
#
#  Recipes source this file.  It expects build.sh to have exported the matrix
#  row for the library being built:
#
#    LIB        matrix name (also the xcframework / include-dir name)
#    VERSION    upstream version string
#    SHA256     sha256 of the source archive ("-" means record, not verify)
#    URL        download URL
#    PLATFORMS  space-separated subset of: ios simulator macosx
#    ARCHS_IOS ARCHS_SIM ARCHS_MAC   space-separated arch lists
#    MIN_IOS MIN_MAC                 deployment targets
#
#  A recipe's contract: build each arch into
#  build/<lib>/<platform>/<arch>/, lipo each library into
#  build/<lib>/<platform>/install/lib/, leave headers under
#  build/<lib>/<platform>/install/include/, set MANIFEST_FLAGS to a readable
#  record of the flags used, then call finish_library with the library file
#  names.  finish_library creates the xcframework, the canonical include dir
#  and the manifest.
#
#  Everything this file writes lives under Compressor/build, Compressor/media,
#  Compressor/src, Compressor/library/<lib>.xcframework,
#  Compressor/library/<lib>/include and Compressor/library/manifests -- all
#  gitignored.  Nothing under the legacy Compressor/library trees is touched.

set -euo pipefail

COMPRESSOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEDIA_DIR="${COMPRESSOR_DIR}/media"
SRC_DIR="${COMPRESSOR_DIR}/src"
BUILD_DIR="${COMPRESSOR_DIR}/build"
LIBRARY_DIR="${COMPRESSOR_DIR}/library"
MANIFEST_DIR="${LIBRARY_DIR}/manifests"

die() {
	echo "error: $*" >&2
	exit 1
}

log() {
	echo "[${LIB:-compressor}] $*"
}

platform_sdk() {
	case "$1" in
		ios) echo iphoneos ;;
		simulator) echo iphonesimulator ;;
		macosx) echo macosx ;;
		*) die "unknown platform '$1'" ;;
	esac
}

platform_archs() {
	case "$1" in
		ios) echo "${ARCHS_IOS}" ;;
		simulator) echo "${ARCHS_SIM}" ;;
		macosx) echo "${ARCHS_MAC}" ;;
		*) die "unknown platform '$1'" ;;
	esac
}

platform_min_version() {
	case "$1" in
		ios | simulator) echo "${MIN_IOS}" ;;
		macosx) echo "${MIN_MAC}" ;;
		*) die "unknown platform '$1'" ;;
	esac
}

# Sysroot + deployment-target flags for one platform (no -arch: configure
# probes want the arch in CC and the sysroot in CFLAGS).
sysroot_flags() {
	local platform="$1"
	local sdk flag
	sdk="$(xcrun --sdk "$(platform_sdk "${platform}")" --show-sdk-path)"
	case "${platform}" in
		ios) flag="-miphoneos-version-min=$(platform_min_version "${platform}")" ;;
		simulator) flag="-mios-simulator-version-min=$(platform_min_version "${platform}")" ;;
		macosx) flag="-mmacosx-version-min=$(platform_min_version "${platform}")" ;;
	esac
	echo "-isysroot ${sdk} ${flag}"
}

# Base CFLAGS for one arch of one platform: arch, sysroot, deployment target.
arch_cflags() {
	echo "-arch $2 $(sysroot_flags "$1")"
}

arch_build_dir() {
	echo "${BUILD_DIR}/${LIB}/$1/$2"
}

platform_install_dir() {
	echo "${BUILD_DIR}/${LIB}/$1/install"
}

# fetch_source <url> <sha256|-> [basename]
#
# Downloads the archive into the content-addressed media cache
# (media/<sha256>-<basename>), verifies it, and extracts it into
# build/<lib>/source.  With sha256 "-" the hash is computed and recorded in
# RECORDED_SHA for pinning into matrix.conf, with a warning.
fetch_source() {
	local url="$1" sha="$2" basename="${3:-}"
	basename="${basename:-$(basename "${url}")}"
	local tmp="${MEDIA_DIR}/.tmp-${basename}"
	local target="${MEDIA_DIR}/${sha}-${basename}"
	local srcroot="${BUILD_DIR}/${LIB}/source"

	mkdir -p "${MEDIA_DIR}"

	if [[ "${sha}" == "-" ]]; then
		if [[ ! -f "${MEDIA_DIR}/unpinned-${basename}" ]]; then
			log "downloading ${url}"
			curl -fsSL -o "${MEDIA_DIR}/unpinned-${basename}" "${url}" \
				|| die "download failed: ${url} (first build needs network access; see DEVELOPER.md)"
		fi
		RECORDED_SHA="$(shasum -a 256 "${MEDIA_DIR}/unpinned-${basename}" | awk '{print $1}')"
		log "WARNING: no sha256 pinned for ${basename}; computed ${RECORDED_SHA}"
		log "WARNING: pin it in matrix.conf and rebuild"
		target="${MEDIA_DIR}/unpinned-${basename}"
	else
		if [[ ! -f "${target}" ]]; then
			log "downloading ${url}"
			curl -fsSL -o "${tmp}" "${url}" \
				|| die "download failed: ${url} (first build needs network access; see DEVELOPER.md)"
			local actual
			actual="$(shasum -a 256 "${tmp}" | awk '{print $1}')"
			[[ "${actual}" == "${sha}" ]] \
				|| die "sha256 mismatch for ${basename}: expected ${sha}, got ${actual}"
			mv "${tmp}" "${target}"
		fi
	fi

	log "extracting ${target}"
	rm -rf "${srcroot}"
	mkdir -p "${srcroot}/.extract"

	case "${target}" in
		*.zip) unzip -q "${target}" -d "${srcroot}/.extract" || die "extract failed: ${target}" ;;
		*.tar.gz | *.tgz) tar -xzf "${target}" -C "${srcroot}/.extract" || die "extract failed: ${target}" ;;
		*.tar.bz2) tar -xjf "${target}" -C "${srcroot}/.extract" || die "extract failed: ${target}" ;;
		*.tar.xz) tar -xJf "${target}" -C "${srcroot}/.extract" || die "extract failed: ${target}" ;;
		*) die "unknown archive type: ${target}" ;;
	esac

	# Normalize: most archives carry one top-level directory; move its
	# contents up so SRC_ROOT is that directory.
	local top
	top="$(ls -1 "${srcroot}/.extract" | grep -v '^\.' | head -1)"
	if [[ -d "${srcroot}/.extract/${top}" ]] \
		&& [[ "$(ls -1 "${srcroot}/.extract" | wc -l | tr -d ' ')" == "1" ]]; then
		mv "${srcroot}/.extract/${top}" "${srcroot}/src"
		rm -rf "${srcroot}/.extract"
		SRC_ROOT="${srcroot}/src"
	else
		# Flat archive: the extract dir itself is the source root.
		SRC_ROOT="${srcroot}/.extract"
	fi

	log "source ready at ${SRC_ROOT}"
}

# lipo_platform <platform> <libname...>
#
# Merges the per-arch archives named by <libname...> into
# build/<lib>/<platform>/install/lib/<libname>.
lipo_platform() {
	local platform="$1"
	shift
	local install
	install="$(platform_install_dir "${platform}")"
	mkdir -p "${install}/lib"

	local lib arch inputs
	for lib in "$@"; do
		inputs=()
		for arch in $(platform_archs "${platform}"); do
			inputs+=("$(arch_build_dir "${platform}" "${arch}")/${lib}")
		done
		xcrun lipo -create "${inputs[@]}" -output "${install}/lib/${lib}"
	done
}

# install_headers_from <platform>
#
# Copies one platform's headers into the platform install dir.  Headers can
# differ per platform (freetds generates tds_sysdep_public.h per build); the
# canonical include dir takes the headers of the first platform built, and the
# manifest records which platform that was.
install_headers_from() {
	local platform="$1"
	local install src
	install="$(platform_install_dir "${platform}")"
	src="${SRC_HEADERS_DIR:-}"
	if [[ -z "${src}" ]]; then
		src="$(arch_build_dir "${platform}" "$(platform_archs "${platform}" | awk '{print $1}')")/include"
	fi
	[[ -d "${src}" ]] || die "no include dir at ${src} (SRC_HEADERS_DIR not set?)"
	rm -rf "${install}/include"
	cp -R "${src}" "${install}/include"
}

# finish_library <libname...>
#
# Assembles the final artifacts from the per-platform installs: the
# xcframework, the canonical include dir and the manifest.
finish_library() {
	local libnames=("$@")
	[[ ${#libnames[@]} -gt 0 ]] || die "finish_library: no library names given"

	local platform xcargs=() first_headers="" lib
	for platform in ${PLATFORMS}; do
		local install
		install="$(platform_install_dir "${platform}")"
		[[ -f "${install}/lib/${libnames[0]}" ]] \
			|| die "finish_library: ${install}/lib/${libnames[0]} not built"

		if [[ -z "${first_headers}" ]]; then
			first_headers="${platform}"
		fi

		# No -platform hints: this Xcode's -create-xcframework infers each
		# slice's platform from the library's Mach-O load commands, which
		# the per-platform -m*-version-min flags set correctly.
		for lib in "${libnames[@]}"; do
			xcargs+=(-library "${install}/lib/${lib}" -headers "${install}/include")
		done
	done

	# Canonical include dir: one platform's headers, the same for every
	# consumer regardless of SDK.
	local include_dir="${LIBRARY_DIR}/${LIB}/include"
	rm -rf "${include_dir}"
	mkdir -p "${include_dir}"
	cp -R "$(platform_install_dir "${first_headers}")/include/"* "${include_dir}/"

	local xcfw="${LIBRARY_DIR}/${LIB}.xcframework"
	rm -rf "${xcfw}"
	log "creating ${xcfw}"
	xcodebuild -create-xcframework "${xcargs[@]}" -output "${xcfw}" \
		|| die "xcodebuild -create-xcframework failed"

	write_manifest "${first_headers}" "${libnames[@]}"
	log "${LIB} ready: ${xcfw}"
}

# write_manifest <headers-platform> <libname...>
write_manifest() {
	local headers_platform="$1"
	shift
	local libnames=("$@")
	mkdir -p "${MANIFEST_DIR}"
	local manifest="${MANIFEST_DIR}/${LIB}.json"
	local slice_entries="" first=1
	local platform install sha
	for platform in ${PLATFORMS}; do
		install="$(platform_install_dir "${platform}")"
		sha="$(shasum -a 256 "${install}/lib/${libnames[0]}" | awk '{print $1}')"
		[[ "${first}" == "1" ]] || slice_entries+=$',\n'
		first=0
		slice_entries+="    \"${platform}\": { \"archs\": \"$(platform_archs "${platform}")\", \"sha256\": \"${sha}\" }"
	done

	local flags_escaped
	flags_escaped="${MANIFEST_FLAGS:-}"

	cat > "${manifest}" <<EOF
{
  "library": "${LIB}",
  "version": "${VERSION}",
  "source": { "url": "${URL}", "sha256": "${SHA256}" },
  "toolchain": { "xcode": "$(xcodebuild -version | head -1)", "clang": "$(xcrun --find clang)" },
  "headers": "${headers_platform}",
  "flags": "${flags_escaped}",
  "built": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "slices": {
${slice_entries}
  }
}
EOF
}
