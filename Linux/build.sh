#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  build.sh -- the Linux entry point (docs/project/MAD_LINUX.md §9).
#
#  Builds the toolchain image, compiles the ten headless frameworks and the `mad`
#  CLI inside it, and runs the Linux tests.  The runtime image is the CLI
#  deliverable: `mad` on PATH, the libraries it links, and the Sqlite3 sample
#  database -- no compiler, sources or test binaries.  `--verify` runs the CLI
#  end to end against the checked-in fixtures and their pinned digests.
#
#  Usage:
#    build.sh                 build the build image, run the tests
#    build.sh --test          run the tests in the existing build image
#    build.sh --runtime       build the runtime image (mad-cli:latest)
#    build.sh --verify        build the runtime image, then verify the CLI in it
#    build.sh --probe         run only the toolchain probe, with its report
#    build.sh --info          print clang and gnustep-config from the image
#    build.sh --shell         interactive shell in the build image
#    build.sh --toolchain     build only the toolchain image (the cache base)
#    build.sh --rebuild       rebuild the images without cache
#    build.sh --clean         remove the build, toolchain and runtime images
#    build.sh --platform P    docker --platform (default: native)
#    build.sh --in-image S    internal: configure | build | test | probe
#
#  The docker CLI is found on PATH or at Docker Desktop's bundle, and the build
#  context is the repo root (.dockerignore keeps it to the sources).

set -euo pipefail

LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${LINUX_DIR}/.." && pwd)"
. "${LINUX_DIR}/lib/common.sh"

IMAGE="${MAD_LINUX_IMAGE:-mad-linux:phase-b}"
TOOLCHAIN_IMAGE="${MAD_LINUX_TOOLCHAIN_IMAGE:-mad-linux-toolchain:1}"
RUNTIME_IMAGE="${MAD_LINUX_RUNTIME_IMAGE:-mad-cli:latest}"
BUILD_DIR="${LINUX_DIR}/build"

MODE=all
REBUILD=0
PLATFORM="${MAD_LINUX_PLATFORM:-}"

usage() { # -> prints the header comment
	sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

setup_docker_path() { # put Docker Desktop's bundle on PATH when the CLI is elsewhere
	local bundled_dir="/Applications/Docker.app/Contents/Resources/bin"
	if [[ -x "${bundled_dir}/docker" ]]; then
		# Not just the CLI: docker-credential-desktop lives beside it and the
		# CLI looks for that on PATH.
		PATH="${bundled_dir}:${PATH}"
		export PATH
	fi
}

docker_bin() { # -> echoes the docker command to use
	command -v docker >/dev/null 2>&1 || die "docker not found (PATH or Docker Desktop's bundle)"
	echo docker
}

build_image() { # build the build-stage image
	local db args=()
	db="$(docker_bin)"
	# --target build is required: the runtime stage is the Dockerfile's last
	# stage, so without it the default target would be the CLI deliverable.
	args=(build -f "${LINUX_DIR}/Dockerfile" --target build)
	if [[ "${REBUILD}" == "1" ]]; then args+=(--no-cache); fi
	if [[ -n "${PLATFORM}" ]]; then args+=(--platform "${PLATFORM}"); fi
	log "build ${IMAGE} (build stage)"
	( cd "${REPO_ROOT}" && "${db}" "${args[@]}" -t "${IMAGE}" . )
}

build_toolchain_image() { # build the toolchain-stage image only
	local db args=()
	db="$(docker_bin)"
	args=(build -f "${LINUX_DIR}/Dockerfile" --target toolchain)
	if [[ "${REBUILD}" == "1" ]]; then args+=(--no-cache); fi
	if [[ -n "${PLATFORM}" ]]; then args+=(--platform "${PLATFORM}"); fi
	log "build ${TOOLCHAIN_IMAGE} (toolchain stage)"
	( cd "${REPO_ROOT}" && "${db}" "${args[@]}" -t "${TOOLCHAIN_IMAGE}" . )
}

build_runtime_image() { # build the runtime stage: the `mad` deliverable
	local db args=()
	db="$(docker_bin)"
	args=(build -f "${LINUX_DIR}/Dockerfile" --target runtime)
	if [[ "${REBUILD}" == "1" ]]; then args+=(--no-cache); fi
	if [[ -n "${PLATFORM}" ]]; then args+=(--platform "${PLATFORM}"); fi
	log "build ${RUNTIME_IMAGE} (runtime stage)"
	( cd "${REPO_ROOT}" && "${db}" "${args[@]}" -t "${RUNTIME_IMAGE}" . )
}

run_verify() { # build the runtime image, then run the CLI end-to-end checks in it
	local db args=()
	db="$(docker_bin)"
	build_runtime_image
	log "verify ${RUNTIME_IMAGE}"
	args=(run --rm)
	if [[ -n "${PLATFORM}" ]]; then args+=(--platform "${PLATFORM}"); fi
	# The repo is mounted read-only: the verification writes only to /tmp.
	"${db}" "${args[@]}" --entrypoint bash \
		-v "${REPO_ROOT}:/repo:ro" \
		"${RUNTIME_IMAGE}" /repo/Linux/verify-cli.sh
}

run_image() { # [command...] -> docker run --rm IMAGE command...
	local db args=()
	db="$(docker_bin)"
	args=(run --rm)
	if [[ -n "${PLATFORM}" ]]; then args+=(--platform "${PLATFORM}"); fi
	"${db}" "${args[@]}" "${IMAGE}" "$@"
}

run_shell() { # interactive shell in the build image
	local db args=()
	db="$(docker_bin)"
	args=(run --rm -it)
	if [[ -n "${PLATFORM}" ]]; then args+=(--platform "${PLATFORM}"); fi
	"${db}" "${args[@]}" "${IMAGE}" bash
}

clean_images() { # remove the build, toolchain and runtime images
	local db
	db="$(docker_bin)"
	"${db}" image rm -f "${IMAGE}" "${TOOLCHAIN_IMAGE}" "${RUNTIME_IMAGE}" || true
	echo "OK linux-phase-b: images removed"
}

in_image_configure() {
	cmake -S "${LINUX_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Debug
}

in_image_build() {
	in_image_configure
	cmake --build "${BUILD_DIR}" -j"$(nproc)"
	echo "OK linux-phase-b: subset built"
}

in_image_test() {
	local out clean rc=0 needs reports
	# -V so every executable's MADTEST/REPORT/NEED lines are in the capture;
	# ctest prefixes test output with "<number>: ", stripped here before
	# parsing.  Only the summaries are printed when everything passes.
	out="$(ctest --test-dir "${BUILD_DIR}" -V -j"$(nproc)" 2>&1)" || rc=$?
	clean="$(printf '%s\n' "${out}" | sed 's/^[[:space:]]*[0-9][0-9]*: //')"
	if [[ "${rc}" != "0" ]]; then
		printf '%s\n' "${clean}" | grep -E "^MADTEST |^NEED:|EXCEPTION|Failed|tests passed" | tail -40 || true
		echo "FAIL linux-phase-b: tests failed (exit ${rc})"
		return "${rc}"
	fi
	printf '%s\n' "${clean}" | grep '^MADTEST ' | sort || true
	printf '%s\n' "${clean}" | grep '^NEED:' | sort || true
	printf '%s\n' "${clean}" | grep -oE '[0-9]+% tests passed[^.]*' | tail -1 || true
	needs="$(printf '%s\n' "${clean}" | sed -n 's/^MADTEST .* needs=\([0-9]*\).*/\1/p' | awk '{n+=$1} END{print n+0}')"
	reports="$(printf '%s\n' "${clean}" | grep -c '^REPORT ' || true)"
	echo "OK linux-phase-b: ${needs} need(s), ${reports} report item(s)"
}

in_image_probe() {
	[[ -x "${BUILD_DIR}/ToolchainProbe" ]] || die "probe not built; run build.sh --in-image build first"
	"${BUILD_DIR}/ToolchainProbe"
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--test) MODE=test ;;
			--runtime) MODE=runtime ;;
			--verify) MODE=verify ;;
			--probe) MODE=probe ;;
			--info) MODE=info ;;
			--shell) MODE=shell ;;
			--toolchain) MODE=toolchain ;;
			--clean) MODE=clean ;;
			--rebuild) REBUILD=1 ;;
			--platform)
				shift
				PLATFORM="${1:-}"
				[[ -n "${PLATFORM}" ]] || die "--platform needs a value"
				;;
			--in-image)
				shift
				MODE="in-image:${1:-}"
				;;
			-h | --help)
				usage
				exit 0
				;;
			*) die "unknown option: $1 (try --help)" ;;
		esac
		shift
	done
}

main() {
	parse_args "$@"
	setup_docker_path
	case "${MODE}" in
		all)
			build_image
			run_image
			;;
		test) run_image ;;
		runtime) build_runtime_image ;;
		verify) run_verify ;;
		probe) run_image bash Linux/build.sh --in-image probe ;;
		info)
			run_image sh -c 'clang --version | head -1; echo; gnustep-config --objc-flags; echo; gnustep-config --base-libs'
			;;
		shell) run_shell ;;
		toolchain) build_toolchain_image ;;
		clean) clean_images ;;
		in-image:configure) in_image_configure ;;
		in-image:build) in_image_build ;;
		in-image:test) in_image_test ;;
		in-image:probe) in_image_probe ;;
		*) die "unknown mode: ${MODE} (try --help)" ;;
	esac
}

main "$@"
