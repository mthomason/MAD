#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  Samples/check.sh -- drive the curated samples through the macOS app objects.
#
#  Builds a small AppKit tool from the same sources as the app and runs it
#  against Samples/Reports.  It refreshes each sample with no stored password,
#  checks the connection prompt, selects every composition node, checks the
#  row grid, copies the folder outside the repo, saves and reopens, and writes
#  PNG/PDF snapshots under Samples/Screenshots.
#
#  Usage:
#    ./Samples/check.sh [--no-build]
#
#  The PostgreSQL sample is checked only when MAD_PG_SAMPLE_PASSWORD is set.
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly BUILD_DIR="${SCRIPT_DIR}/build"
readonly OUTPUT="${BUILD_DIR}/mad-sample-check"
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

readonly APP_SOURCES=(
	"${REPO_ROOT}/Mac/Source/MADMacDocument.m"
	"${REPO_ROOT}/Mac/Source/MADMacDocumentController.m"
	"${REPO_ROOT}/Mac/Source/MADMacWindowController.m"
	"${REPO_ROOT}/Mac/Source/MADMacConnectionWindowController.m"
	"${REPO_ROOT}/Mac/Source/MADMacQueryViewController.m"
	"${REPO_ROOT}/Mac/Source/MADMacDesignerViewController.m"
	"${REPO_ROOT}/Mac/Source/MADMacDesignerCanvasView.m"
	"${REPO_ROOT}/Mac/Source/MADMacViewerViewController.m"
	"${REPO_ROOT}/Mac/Source/MADMacTipBar.m"
	"${REPO_ROOT}/MADDesigner/Source/MADColorTransformer.m"
	"${REPO_ROOT}/MADDesigner/Source/MADLocaleTransformer.m"
	"${REPO_ROOT}/MADDesigner/Resources/MADFileDefinition/MADPngImageTransformer.m"
	"${REPO_ROOT}/MADDesigner/Source/MADStoreLegacy/MADStoreConverter.m"
	"${REPO_ROOT}/MADDesigner/Source/MADStoreLegacy/MADStoreLegacyConverter.m"
)

if [[ ! -d "${APP_FRAMEWORKS}" ]]; then
	echo "Missing ${APP_FRAMEWORKS}." >&2
	echo "Run ./Mac/build.sh first." >&2
	exit 1
fi

if [[ "${1:-}" != "--no-build" ]]; then
	mkdir -p "${BUILD_DIR}"
	framework_flags=()
	for framework in "${FRAMEWORKS[@]}"; do
		framework_flags+=("-framework" "${framework}")
	done
	echo "Compiling mad-sample-check..."
	xcrun --sdk macosx clang \
		-fobjc-arc \
		-g -O0 \
		-target arm64-apple-macos12.0 \
		-I "${REPO_ROOT}/Mac/Source" \
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
		-F "${APP_FRAMEWORKS}" \
		"${framework_flags[@]}" \
		-framework Cocoa \
		-framework CoreData \
		-framework Quartz \
		-framework WebKit \
		-framework UniformTypeIdentifiers \
		-framework Security \
		-Wl,-rpath,"${APP_FRAMEWORKS}" \
		"${SCRIPT_DIR}/Tools/MADSampleCheck.m" \
		"${APP_SOURCES[@]}" \
		-o "${OUTPUT}"
	codesign --force --sign - "${OUTPUT}"
fi

exec "${OUTPUT}" "${SCRIPT_DIR}/Reports" "${BUILD_DIR}/Screenshots"
