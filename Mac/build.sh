#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  Mac/build.sh -- Build, bundle, test, and package the native macOS MAD Designer app.
#
#  Usage:
#    ./Mac/build.sh                     build frameworks + MAD Designer.app
#    ./Mac/build.sh --no-frameworks     build only MAD Designer.app (fast iteration)
#    ./Mac/build.sh --smoke-test        build and run the end-to-end macOS smoke suite
#    ./Mac/build.sh --package           build and create MAD-Designer-macOS.zip + .dmg
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly BUILD_DIR="${SCRIPT_DIR}/build"
readonly APP_NAME="MAD Designer"
readonly APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
readonly CONTENTS_DIR="${APP_BUNDLE}/Contents"
readonly MACOS_DIR="${CONTENTS_DIR}/MacOS"
readonly FRAMEWORKS_DIR="${CONTENTS_DIR}/Frameworks"
readonly RESOURCES_DIR="${CONTENTS_DIR}/Resources"

readonly DEFAULT_DD="${HOME}/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci"
readonly DERIVED_DATA="${MAD_DERIVED_DATA:-${DEFAULT_DD}}"
readonly PRODUCTS="${DERIVED_DATA}/Build/Products/Debug"
readonly DEPLOYMENT_TARGET="12.0"

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

readonly TRANSFORMERS=(
	"${REPO_ROOT}/MADDesigner/Source/MADColorTransformer.m"
	"${REPO_ROOT}/MADDesigner/Source/MADLocaleTransformer.m"
	"${REPO_ROOT}/MADDesigner/Resources/MADFileDefinition/MADPngImageTransformer.m"
)

readonly LEGACY_SOURCES=(
	"${REPO_ROOT}/MADDesigner/Source/MADStoreLegacy/MADStoreConverter.m"
	"${REPO_ROOT}/MADDesigner/Source/MADStoreLegacy/MADStoreLegacyConverter.m"
)

framework_flags() {
	local fw
	for fw in "${FRAMEWORKS[@]}"; do
		printf -- '-framework %s ' "${fw}"
	done
}

build_frameworks() {
	echo "==> Ensuring macOS static libraries (Compressor)..."
	"${REPO_ROOT}/Compressor/build.sh" --verify --all --platforms macosx >/dev/null

	echo "==> Building 12 MAD frameworks for native macOS (arm64, macOS ${DEPLOYMENT_TARGET}+)..."
	local scheme
	for scheme in MADFoundation MADDataStructures MADCocoaExtensions MADFileManager MADAPI MADSqlite3 MADTdsClient MADMySQL MADPostgres MADBarcodes MAD; do
		echo "    - ${scheme}.framework"
		xcodebuild build \
			-workspace "${REPO_ROOT}/Reports.xcworkspace" \
			-scheme "${scheme}" \
			-destination 'platform=macOS,arch=arm64' \
			-derivedDataPath "${DERIVED_DATA}" \
			-quiet < /dev/null
	done
}

assemble_app_bundle() {
	echo "==> Assembling ${APP_BUNDLE}..."
	rm -rf "${APP_BUNDLE}"
	mkdir -p "${MACOS_DIR}" "${FRAMEWORKS_DIR}" "${RESOURCES_DIR}"

	# 1. Info.plist
	sed \
		-e "s/\$(EXECUTABLE_NAME)/${APP_NAME}/g" \
		-e "s/\$(PRODUCT_BUNDLE_IDENTIFIER)/com.thomason.report.mac/g" \
		-e "s/\$(PRODUCT_NAME)/${APP_NAME}/g" \
		-e "s/\$(MACOSX_DEPLOYMENT_TARGET)/${DEPLOYMENT_TARGET}/g" \
		"${SCRIPT_DIR}/Resources/Info.plist" > "${CONTENTS_DIR}/Info.plist"

	# 2. Embed all 12 frameworks
	local fw
	for fw in "${FRAMEWORKS[@]}"; do
		if [[ ! -d "${PRODUCTS}/${fw}.framework" ]]; then
			echo "ERROR: Missing ${PRODUCTS}/${fw}.framework. Run ./Mac/build.sh without --no-frameworks first." >&2
			exit 1
		fi
		cp -R "${PRODUCTS}/${fw}.framework" "${FRAMEWORKS_DIR}/${fw}.framework"
	done

	# 3. Compile Core Data legacy model (MAD.xcdatamodeld -> MAD.momd)
	xcrun momc \
		"${REPO_ROOT}/MADDesigner/Resources/MADFileDefinition/MAD.xcdatamodeld" \
		"${RESOURCES_DIR}/MAD.momd"

	# 4. Bundle sample reports & Chinook SQLite database
	cp "${REPO_ROOT}/CLI/Fixtures/London.portable.mad" "${RESOURCES_DIR}/London.mad"
	cp "${REPO_ROOT}/CLI/Fixtures/Music.portable.mad" "${RESOURCES_DIR}/Music.mad"
	cp "${REPO_ROOT}/MADDesigner/Resources/Assets/Samples.xcassets/Data/chinook.dataset/chinook.sqlite3" "${RESOURCES_DIR}/chinook.sqlite3"

	# 5. Compile native AppKit executable
	echo "==> Compiling ${APP_NAME} (AppKit, arm64-apple-macos${DEPLOYMENT_TARGET})..."
	# shellcheck disable=SC2046
	xcrun --sdk macosx clang \
		-fobjc-arc \
		-g -O2 \
		-target "arm64-apple-macos${DEPLOYMENT_TARGET}" \
		-I "${SCRIPT_DIR}/Source" \
		-I "${REPO_ROOT}/MAD/Source" \
		-I "${REPO_ROOT}/MAD/Source/sql" \
		-I "${REPO_ROOT}/MAD/Source/rptq" \
		-I "${REPO_ROOT}/MAD/Source/rptq/autogen" \
		-I "${REPO_ROOT}/MAD/Source/rptq/store" \
		-I "${REPO_ROOT}/MAD/Source/paper" \
		-I "${REPO_ROOT}/MAD/Source/model" \
		-I "${REPO_ROOT}/MADDesigner/Source" \
		-I "${REPO_ROOT}/MADDesigner/Source/MADStoreLegacy" \
		-I "${REPO_ROOT}/MADDesigner/Resources/MADFileDefinition" \
		-F "${FRAMEWORKS_DIR}" \
		$(framework_flags) \
		-framework Cocoa \
		-framework CoreData \
		-framework Quartz \
		-framework WebKit \
		-framework UniformTypeIdentifiers \
		-Wl,-rpath,@executable_path/../Frameworks \
		"${SCRIPT_DIR}"/Source/*.m \
		"${TRANSFORMERS[@]}" \
		"${LEGACY_SOURCES[@]}" \
		-o "${MACOS_DIR}/${APP_NAME}"

	# 6. Ad-hoc sign embedded frameworks and app bundle
	echo "==> Signing ${APP_BUNDLE}..."
	for fw in "${FRAMEWORKS[@]}"; do
		codesign --force --sign - "${FRAMEWORKS_DIR}/${fw}.framework"
	done
	codesign --force --deep --sign - "${APP_BUNDLE}"
}

run_smoke_test() {
	local smoke_bin="${BUILD_DIR}/mad-mac-smoke-test"
	echo "==> Compiling and running macOS smoke test against bundled frameworks..."
	# shellcheck disable=SC2046
	xcrun --sdk macosx clang \
		-fobjc-arc \
		-g -O0 \
		-target "arm64-apple-macos${DEPLOYMENT_TARGET}" \
		-I "${REPO_ROOT}/MAD/Source" \
		-I "${REPO_ROOT}/MAD/Source/sql" \
		-I "${REPO_ROOT}/MAD/Source/rptq" \
		-I "${REPO_ROOT}/MAD/Source/rptq/autogen" \
		-I "${REPO_ROOT}/MAD/Source/rptq/store" \
		-I "${REPO_ROOT}/MAD/Source/paper" \
		-I "${REPO_ROOT}/MAD/Source/model" \
		-I "${REPO_ROOT}/MADDesigner/Source" \
		-I "${REPO_ROOT}/MADDesigner/Source/MADStoreLegacy" \
		-I "${REPO_ROOT}/MADDesigner/Resources/MADFileDefinition" \
		-F "${FRAMEWORKS_DIR}" \
		$(framework_flags) \
		-framework Cocoa \
		-framework CoreData \
		-Wl,-rpath,"${FRAMEWORKS_DIR}" \
		"${SCRIPT_DIR}/Tests/MADMacSmokeTest.m" \
		"${TRANSFORMERS[@]}" \
		"${LEGACY_SOURCES[@]}" \
		-o "${smoke_bin}"

	codesign --force --sign - "${smoke_bin}"
	"${smoke_bin}" "${APP_BUNDLE}"
}

package_release_artifacts() {
	local zip_out="${BUILD_DIR}/MAD-Designer-macOS.zip"
	local dmg_out="${BUILD_DIR}/MAD-Designer-macOS.dmg"
	local staging="${BUILD_DIR}/dmg-staging"

	echo "==> Creating release archive ${zip_out}..."
	rm -f "${zip_out}"
	ditto -c -k --sequesterRsrc --keepParent "${APP_BUNDLE}" "${zip_out}"

	echo "==> Creating disk image ${dmg_out}..."
	rm -rf "${staging}" "${dmg_out}"
	mkdir -p "${staging}"
	cp -R "${APP_BUNDLE}" "${staging}/${APP_NAME}.app"
	ln -s /Applications "${staging}/Applications"
	hdiutil create \
		-volname "${APP_NAME}" \
		-srcfolder "${staging}" \
		-ov \
		-format UDZO \
		"${dmg_out}" >/dev/null
	rm -rf "${staging}"

	echo "==> Packaged:"
	ls -lh "${zip_out}" "${dmg_out}"
}

BUILD_FW=1
RUN_SMOKE=0
DO_PACKAGE=0

for arg in "$@"; do
	case "${arg}" in
		--no-frameworks) BUILD_FW=0 ;;
		--smoke-test) RUN_SMOKE=1 ;;
		--package) DO_PACKAGE=1 ;;
		*)
			echo "Unknown option: ${arg}" >&2
			exit 1
			;;
	esac
done

if [[ "${BUILD_FW}" -eq 1 ]]; then
	build_frameworks
fi

assemble_app_bundle

if [[ "${RUN_SMOKE}" -eq 1 ]]; then
	run_smoke_test
fi

if [[ "${DO_PACKAGE}" -eq 1 ]]; then
	package_release_artifacts
fi

echo "==> Built: ${APP_BUNDLE}"
