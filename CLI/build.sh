#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  build.sh -- build the `mad` command-line tool.
#
#  The tool is built for the iOS Simulator and run on the Mac through
#  `xcrun simctl spawn`, which is what lets it link the existing frameworks and the
#  existing static libraries without any of them being rebuilt for a second platform.
#  See docs/project/MAD_CLI.md section 4.
#
#  Usage:
#    CLI/build.sh                     build the frameworks, then the tool
#    CLI/build.sh --no-frameworks     build only the tool (fast; use while iterating)
#    CLI/build.sh --run ...           build, then run the tool with the arguments given
#    CLI/build.sh --make-fixture ...   run Fixtures/MADFixtureMaker (Fixtures/README.md)
#
#  The build directory is CLI/build, which is ignored by git.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly BUILD_DIR="${SCRIPT_DIR}/build"
# A project-local DerivedData instead of Xcode's default: the default name carries a
# per-machine hash, so a fresh checkout could not find the frameworks it just built.
readonly DERIVED_DATA="${MAD_DERIVED_DATA:-${REPO_ROOT}/.cli-deriveddata}"
readonly PRODUCTS="${DERIVED_DATA}/Build/Products/Debug-iphonesimulator"
readonly OUTPUT="${BUILD_DIR}/mad"
readonly FIXTURE_OUTPUT="${BUILD_DIR}/mad-fixture-maker"

# The frameworks the tool links, in dependency order.  MADFoundation first is not
# required by the linker, but keeping the list readable is worth something.
#
# The drivers are named here because the framework no longer imports them: a driver
# registers itself when something links it (MADDatabaseDriverRegistry.h, docs/project/ROADMAP.md
# §5.1), so the tool links the ones it runs queries against.  Sqlite3 comes in with
# MAD, which still links it for MADDataTableFast; MySQL and TDS do not.
readonly FRAMEWORKS=(
	MADFoundation
	MADCocoaExtensions
	MADDataStructures
	MADFileManager
	MADSqlite3
	MADAPI
	MAD
	MADMySQL
	MADTdsClient
	MADPostgres
)

# The Core Data model names these as value transformers for its transformable
# attributes.  They live in the app target and register themselves in +load, so a
# process that does not link them cannot decode a colour, an image or a locale out
# of a document.  They are three small classes with no dependencies beyond UIKit.
readonly TRANSFORMERS=(
	"${REPO_ROOT}/MADDesigner/Source/MADColorTransformer.m"
	"${REPO_ROOT}/MADDesigner/Source/MADLocaleTransformer.m"
	"${REPO_ROOT}/MADDesigner/Resources/MADFileDefinition/MADPngImageTransformer.m"
)

# The refresh chain used to be compiled in from the application target; it lives in
# the MAD framework now (docs/project/MAD_CLI.md section 4.1, docs/project/ROADMAP.md §3.4), so the tool takes
# it from -framework MAD like the rest.

# The legacy store converter, compiled in from the application target for the same
# reason: the MAD framework no longer links Core Data (docs/project/MAD_LINUX.md), so a process
# that must open a pre-portable-store document carries the converter itself.  The
# shipping samples are legacy documents, so the CLI needs it.
readonly LEGACY_SOURCES=(
	"${REPO_ROOT}/MADDesigner/Source/MADStoreLegacy/MADStoreConverter.m"
	"${REPO_ROOT}/MADDesigner/Source/MADStoreLegacy/MADStoreLegacyConverter.m"
)

framework_flags() {
	local framework
	for framework in "${FRAMEWORKS[@]}"; do
		printf -- '-framework %s ' "${framework}"
	done
}

build_frameworks() {
	echo "Building frameworks..."
	xcodebuild build \
		-workspace "${REPO_ROOT}/Reports.xcworkspace" \
		-scheme "MAD Designer" \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-derivedDataPath "${DERIVED_DATA}" \
		-quiet
}

compile_tool() {
	mkdir -p "${BUILD_DIR}"
	echo "Compiling mad..."
	# shellcheck disable=SC2046
	xcrun --sdk iphonesimulator clang \
		-fobjc-arc \
		-g -O0 \
		-target arm64-apple-ios15.0-simulator \
		-DNS_BLOCK_ASSERTIONS=1 \
		-I "${SCRIPT_DIR}/Source" \
		-I "${REPO_ROOT}/MAD/Source" \
		-I "${REPO_ROOT}/MADDesigner/Source" \
		-I "${REPO_ROOT}/MADDesigner/Source/MADStoreLegacy" \
		-I "${REPO_ROOT}/MADDesigner/Resources/MADFileDefinition" \
		-F "${PRODUCTS}" \
		$(framework_flags) \
		-framework CoreData \
		-framework CoreGraphics \
		-framework UIKit \
		-Wl,-rpath,"${PRODUCTS}" \
		"${SCRIPT_DIR}"/Source/*.m \
		"${TRANSFORMERS[@]}" \
		"${LEGACY_SOURCES[@]}" \
		-o "${OUTPUT}"

	# UIManagedDocument finds its model with +mergedModelFromBundles:nil, which
	# searches the main bundle.  For a plain executable the main bundle is the
	# directory the binary lives in, so the compiled model has to sit beside it.
	rm -rf "${BUILD_DIR}/MAD.momd"
	cp -R "${PRODUCTS}/MAD Designer.app/MAD.momd" "${BUILD_DIR}/MAD.momd"

	sign_tool
}

# The tool carries the application group entitlement for the same reason the app
# does: MADDatabaseConnectionSqlite3 resolves the sample database through
# -containerURLForSecurityApplicationGroupIdentifier:, which answers nil to a
# process that does not claim the group and then trips an assert inside
# MADURLFactory.  Ad-hoc signing is enough on the simulator, and it is what puts
# the tool in the same container the application has already populated.
sign_tool() {
	codesign --force --sign - \
		--entitlements "${SCRIPT_DIR}/mad.entitlements" \
		"${OUTPUT}"
}

# The fixture maker: the same compile, with Fixtures/MADFixtureMaker.m in place of
# Source/main.m.  It opens and saves a document (the app's own path), which is how
# a legacy sample becomes a portable fixture the Linux CLI can read -- see
# Fixtures/README.md.
compile_fixture_maker() {
	mkdir -p "${BUILD_DIR}"
	echo "Compiling mad-fixture-maker..."
	xcrun --sdk iphonesimulator clang \
		-fobjc-arc \
		-g -O0 \
		-target arm64-apple-ios15.0-simulator \
		-DNS_BLOCK_ASSERTIONS=1 \
		-I "${SCRIPT_DIR}/Source" \
		-I "${REPO_ROOT}/MAD/Source" \
		-I "${REPO_ROOT}/MADDesigner/Source" \
		-I "${REPO_ROOT}/MADDesigner/Source/MADStoreLegacy" \
		-I "${REPO_ROOT}/MADDesigner/Resources/MADFileDefinition" \
		-F "${PRODUCTS}" \
		$(framework_flags) \
		-framework CoreData \
		-framework CoreGraphics \
		-framework UIKit \
		-Wl,-rpath,"${PRODUCTS}" \
		"${SCRIPT_DIR}/Fixtures/MADFixtureMaker.m" \
		"${TRANSFORMERS[@]}" \
		"${LEGACY_SOURCES[@]}" \
		-o "${FIXTURE_OUTPUT}"

	rm -rf "${BUILD_DIR}/MAD.momd"
	cp -R "${PRODUCTS}/MAD Designer.app/MAD.momd" "${BUILD_DIR}/MAD.momd"
}

if [[ "${1:-}" == "--make-fixture" ]]; then
	shift
	build_frameworks
	compile_fixture_maker
	exec env SIMCTL_CHILD_MAD_HOST_CWD="${PWD}" xcrun simctl spawn booted "${FIXTURE_OUTPUT}" "$@"
fi

if [[ "${1:-}" == "--no-frameworks" ]]; then
	shift
	compile_tool
else
	build_frameworks
	compile_tool
fi

if [[ "${1:-}" == "--run" ]]; then
	shift
	# A spawned process starts in the simulator's own home, so a relative path would
	# resolve against that rather than the shell's directory.  Pass the real one
	# through and let the tool join them; SIMCTL_CHILD_ is how simctl forwards an
	# environment variable to the process it spawns.
	exec env SIMCTL_CHILD_MAD_HOST_CWD="${PWD}" xcrun simctl spawn booted "${OUTPUT}" "$@"
fi

echo "Built ${OUTPUT}"
echo "Run with: CLI/build.sh --run <command> <document.mad>"
