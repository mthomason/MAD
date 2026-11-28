#!/bin/bash
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  scripts/dev/build-info.sh -- write a build's identity from Versions.yml + git.
#
#  Usage:
#    build-info.sh --output PATH [--format plist|json] [--manifest PATH]
#                  [--app-version V] [--app-build N]
#                  [--commit SHA] [--build-number N] [--dirty true|false]
#
#  The app version comes from Versions.yml.  The build number is the git commit
#  count at build time; MADEngineRevision is that number as rNNNN.  A build with
#  no .git (the Linux image's Docker context) passes --commit, --build-number,
#  and --dirty instead, so the identity still names the source it came from.  The
#  output is a build product: it is never a tracked plist, and the script writes
#  nothing except the requested file.  Read it with MADCLIBuildInfo(), AppDelegate
#  +buildInfoForBundle:, or Windows BuildInfo.

set -euo pipefail

usage() {
	sed -n 's/^#  \{0,2\}//p' "$0" | sed -n '1,12p'
}

manifest=""
output=""
format="plist"
app_version=""
app_build=""
commit_override=""
build_number_override=""
dirty_override=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--output)			output="$2"; shift 2 ;;
		--format)			format="$2"; shift 2 ;;
		--manifest)			manifest="$2"; shift 2 ;;
		--app-version)		app_version="$2"; shift 2 ;;
		--app-build)		app_build="$2"; shift 2 ;;
		--commit)			commit_override="$2"; shift 2 ;;
		--build-number)		build_number_override="$2"; shift 2 ;;
		--dirty)			dirty_override="$2"; shift 2 ;;
		-h|--help)			usage; exit 0 ;;
		*) echo "build-info.sh: unknown option $1" >&2; exit 2 ;;
	esac
done

if [[ -z "$output" ]]; then
	echo "build-info.sh: --output is required" >&2
	exit 2
fi
if [[ -z "$manifest" ]]; then
	root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
	manifest="${root}/Versions.yml"
fi
if [[ ! -f "$manifest" ]]; then
	echo "build-info.sh: no manifest at $manifest" >&2
	exit 2
fi

manifest_root="$(cd "$(dirname "$manifest")" && pwd)"

value() {
	awk -F': *' -v key="$1" '
		$1 == key { gsub(/"/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit }
	' "$manifest"
}

app_version="${app_version:-$(value macos_app_version)}"
engine_version="$(value engine_version)"
container_format="$(value container_major).$(value container_minor)"
store_revision="$(value store_revision)"
protocol_version="$(value serve_protocol_version)"

if [[ -n "$build_number_override" ]]; then
	if ! [[ "$build_number_override" =~ ^[0-9]+$ ]]; then
		echo "build-info.sh: --build-number must be a non-negative integer" >&2
		exit 2
	fi
	build_number="$build_number_override"
else
	build_number="$(git -C "$manifest_root" rev-list --count HEAD 2>/dev/null || echo 0)"
	if ! [[ "$build_number" =~ ^[0-9]+$ ]]; then
		build_number=0
	fi
fi
engine_revision="r${build_number}"
app_build="${app_build:-${build_number}}"

if [[ -n "$commit_override" ]]; then
	commit="$commit_override"
else
	commit="$(git -C "$manifest_root" rev-parse HEAD 2>/dev/null || echo unknown)"
fi
if [[ -z "$commit" || "$commit" == "unknown" ]]; then
	commit="unknown"
	short="unknown"
else
	short="${commit:0:8}"
fi

if [[ -n "$dirty_override" ]]; then
	case "$dirty_override" in
		true|false) dirty="$dirty_override" ;;
		*) echo "build-info.sh: --dirty must be true or false" >&2; exit 2 ;;
	esac
elif [[ "$commit" == "unknown" ]]; then
	dirty="false"
elif [[ -n "$(git -C "$manifest_root" status --porcelain 2>/dev/null || true)" ]]; then
	dirty="true"
else
	dirty="false"
fi

build_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p "$(dirname "$output")"
temporary="${output}.tmp.$$"
trap 'rm -f "$temporary"' EXIT

if [[ "$format" == "plist" ]]; then
	if [[ "$dirty" == "true" ]]; then dirty_xml="<true/>"; else dirty_xml="<false/>"; fi
	cat > "$temporary" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>MADAppVersion</key>
	<string>${app_version}</string>
	<key>MADAppBuild</key>
	<string>${app_build}</string>
	<key>MADBuildNumber</key>
	<string>${build_number}</string>
	<key>MADEngineVersion</key>
	<string>${engine_version}</string>
	<key>MADEngineRevision</key>
	<string>${engine_revision}</string>
	<key>MADSourceCommit</key>
	<string>${commit}</string>
	<key>MADSourceCommitShort</key>
	<string>${short}</string>
	<key>MADSourceDirty</key>
	${dirty_xml}
	<key>MADBuildDate</key>
	<string>${build_date}</string>
	<key>MADServeProtocolVersion</key>
	<string>${protocol_version}</string>
	<key>MADContainerFormat</key>
	<string>${container_format}</string>
	<key>MADStoreRevision</key>
	<string>${store_revision}</string>
</dict>
</plist>
EOF
elif [[ "$format" == "json" ]]; then
	cat > "$temporary" <<EOF
{
	"MADAppVersion": "${app_version}",
	"MADAppBuild": "${app_build}",
	"MADBuildNumber": "${build_number}",
	"MADEngineVersion": "${engine_version}",
	"MADEngineRevision": "${engine_revision}",
	"MADSourceCommit": "${commit}",
	"MADSourceCommitShort": "${short}",
	"MADSourceDirty": ${dirty},
	"MADBuildDate": "${build_date}",
	"MADServeProtocolVersion": "${protocol_version}",
	"MADContainerFormat": "${container_format}",
	"MADStoreRevision": "${store_revision}"
}
EOF
else
	echo "build-info.sh: --format must be plist or json" >&2
	exit 2
fi

mv "$temporary" "$output"
trap - EXIT
