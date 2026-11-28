#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  buildcounter.sh -- write the generated build identity for the app targets.
#
#  This is a Run Script build phase on the iOS app, the viewer, and the Mac app.
#  It writes MADBuildInfo.plist into the built product and sets the built
#  Info.plist's CFBundleShortVersionString/CFBundleVersion.  It never reads or
#  rewrites a tracked plist.  Standalone runs (no TARGET_BUILD_DIR) do nothing
#  and succeed, so the script is safe to invoke by hand.
#
#  The build number is the git commit count.  On iOS it is raised to
#  max(count, ios_build_floor + 1) so an App Store submission always increases.

set -euo pipefail

if [[ -z "${TARGET_BUILD_DIR:-}" || -z "${UNLOCALIZED_RESOURCES_FOLDER_PATH:-}" ]]; then
	exit 0
fi

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")" && pwd)}"
REPO_ROOT="$(cd "${PROJECT_DIR}/.." && pwd)"
MANIFEST="${REPO_ROOT}/Versions.yml"

if [[ ! -f "${MANIFEST}" ]]; then
	echo "warning: buildcounter.sh: no ${MANIFEST}; build identity not written" >&2
	exit 0
fi

manifest_value() {
	awk -F': *' -v key="$1" '
		$1 == key { gsub(/"/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit }
	' "${MANIFEST}"
}

build_number="$(git -C "${REPO_ROOT}" rev-list --count HEAD 2>/dev/null || echo 0)"
if ! [[ "${build_number}" =~ ^[0-9]+$ ]]; then
	build_number=0
fi

if [[ "${PLATFORM_NAME:-}" == macosx* ]]; then
	app_version="$(manifest_value macos_app_version)"
	app_build="${build_number}"
else
	app_version="$(manifest_value ios_app_version)"
	ios_floor="$(manifest_value ios_build_floor)"
	if ! [[ "${ios_floor}" =~ ^[0-9]+$ ]]; then
		ios_floor=0
	fi
	if (( 10#${build_number} > 10#${ios_floor} )); then
		app_build="${build_number}"
	else
		app_build="$((10#${ios_floor} + 1))"
	fi
fi

destination="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/MADBuildInfo.plist"
mkdir -p "$(dirname "${destination}")"

"${REPO_ROOT}/scripts/dev/build-info.sh" --format plist \
	--output "${destination}" \
	--app-version "${app_version}" --app-build "${app_build}"

info_plist="${TARGET_BUILD_DIR}/${INFOPLIST_PATH:-}"
if [[ -n "${INFOPLIST_PATH:-}" && -f "${info_plist}" ]]; then
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${app_version}" "${info_plist}"
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${app_build}" "${info_plist}"
fi
