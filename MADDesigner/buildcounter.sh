#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  buildcounter.sh -- write the generated build identity for the iOS app targets.
#
#  This is a Run Script build phase.  It writes MADBuildInfo.plist into the built
#  product only; it never reads or rewrites a tracked plist.  Standalone runs (no
#  TARGET_BUILD_DIR) do nothing and succeed, so the script is safe to invoke by hand.
#
#  The app version and build come from Versions.yml (ios_app_version, ios_build).

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

app_version="$(manifest_value ios_app_version)"
app_build="$(manifest_value ios_build)"

destination="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/MADBuildInfo.plist"
mkdir -p "$(dirname "${destination}")"

"${REPO_ROOT}/scripts/dev/build-info.sh" --format plist \
	--output "${destination}" \
	--app-version "${app_version}" --app-build "${app_build}"
