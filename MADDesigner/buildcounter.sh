#!/bin/bash

exit 0

# buildcounter.sh
# MAD
#
# Original script by Michael Thomason on 3/4/14.
# Copyright © 2025 Michael Thomason. All rights reserved.

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error.
# Pipelines fail if any command fails, not just the last one.
# Updated to disable writing to `Info.plist`.
set -euo pipefail

echo "🚀 Starting Build Counter Script..."

# --- Configuration ---
# Set OVERRIDE_VERSION to a specific value (e.g., "9.0") to force that version.
# After your release, you should set this back to "" to resume automatic git-tag-based versioning.
OVERRIDE_VERSION="9.0"

# Dynamically determine the directory containing the script.
# This makes the script portable and independent of the execution context.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Use the PROJECT_DIR from the environment if available (e.g., from Xcode),
# otherwise, assume the project directory is the script's directory.
PROJECT_DIR="${PROJECT_DIR:-$SCRIPT_DIR}"
MAD_META_PLIST_PATH="${PROJECT_DIR}/MADStack/MADDesigner/Assets/MADMeta.plist"
INFO_PLIST_TARGET_PATHS=(
    "${PROJECT_DIR}/MADStack/MADDesigner/Info.plist"
    # Add other Info.plist paths here if needed
)
# --- End Configuration ---

echo "Project directory: ${PROJECT_DIR}"
cd "$PROJECT_DIR" || { echo "❌ Error: Could not change to project directory '${PROJECT_DIR}'."; exit 1; }
echo "Working directory: $(pwd)"

# Helper function to print a value from a plist file
# Returns empty string if key not found (stderr is suppressed)
print_plist_value() {
    local command_str="$1"
    local plist_file="$2"
    /usr/libexec/PlistBuddy -c "${command_str}" "${plist_file}" 2>/dev/null
}

# Robust helper function to add a new key or set an existing one with a specific type
# Usage: add_or_set_plist_key ":KeyName" "KeyValue" "KeyType" "path/to/plist.plist"
add_or_set_plist_key() {
    local key_path="$1"
    local value="$2"
    local type="$3" # e.g., string, integer, bool
    local plist_file="$4"

    # Check if key exists by attempting to print it
    /usr/libexec/PlistBuddy -c "Print ${key_path}" "${plist_file}" >/dev/null 2>&1
    if [ $? -ne 0 ]; then # Key does not exist
        /usr/libexec/PlistBuddy -c "Add ${key_path} ${type} ${value}" "${plist_file}"
        if [ $? -ne 0 ]; then
            echo "⚠️ Warning: PlistBuddy ADD failed: '${key_path} ${type} ${value}' on '${plist_file}'." >&2
        fi
    else # Key exists
        /usr/libexec/PlistBuddy -c "Set ${key_path} ${value}" "${plist_file}"
        if [ $? -ne 0 ]; then
            echo "⚠️ Warning: PlistBuddy SET failed: '${key_path} ${value}' on '${plist_file}'." >&2
        fi
    fi
}

# Helper function for basic "Set" operations, typically for Info.plist CFBundle keys
# where PlistBuddy's default type inference for Set is usually sufficient.
set_bundle_plist_value() {
    local command_str="$1" # Expected "Set :Key Value"
    local plist_file="$2"
    /usr/libexec/PlistBuddy -c "${command_str}" "${plist_file}"
    if [ $? -ne 0 ]; then
        echo "⚠️ Warning: PlistBuddy command failed: '${command_str}' on '${plist_file}'. The key might not have been set correctly." >&2
    fi
}

# Validate MADMeta.plist path and attempt to create if it doesn't exist
if [ ! -f "$MAD_META_PLIST_PATH" ]; then
    echo "ℹ️ Info: MADMeta.plist not found at '$MAD_META_PLIST_PATH'. Attempting to create it."
    mkdir -p "$(dirname "$MAD_META_PLIST_PATH")"
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict/></plist>" > "$MAD_META_PLIST_PATH"
    if [ ! -f "$MAD_META_PLIST_PATH" ]; then
        echo "❌ Error: Could not create MADMeta.plist at '$MAD_META_PLIST_PATH'. Please create it manually or check permissions."
        exit 1
    fi
    echo "✅ MADMeta.plist created at $MAD_META_PLIST_PATH"
else
    echo "✅ MADMeta.plist found at: $MAD_META_PLIST_PATH"
fi

# Validate Info.plist files from INFO_PLIST_TARGET_PATHS
valid_info_plists=()
for plist_path in "${INFO_PLIST_TARGET_PATHS[@]}"; do
    if [ -z "$plist_path" ]; then
        echo "⚠️ Warning: An empty Info.plist path was provided in INFO_PLIST_TARGET_PATHS. Skipping."
        continue
    fi
    if [ ! -f "$plist_path" ]; then
        echo "⚠️ Warning: Target Info.plist file not found at '$plist_path'. It will be skipped for CFBundle updates."
    else
        echo "✅ Found target Info.plist for CFBundle updates: $plist_path"
        valid_info_plists+=("$plist_path")
    fi
done
INFO_PLIST_TARGET_PATHS=("${valid_info_plists[@]}")
# --- Git Information Fetching ---
echo "⚙️ Fetching version and build information from git..."
calculated_short_version_string="0.1.0" # Default fallback
git_commit_count="0" # Default fallback
git_exact_tag_no_v="0.0.0 (no tag)"
git_describe_output_for_mad="N/A"
git_commit_hash="unknown"
git_branch_name="unknown"
is_dirty_output=""

git_describe_output=$(git describe --tags --dirty --always 2>/dev/null || echo "")

if [[ -z "$git_describe_output" ]] || ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "⚠️ Warning: Not a git repository or 'git describe' failed. Using fallback versioning."
else
    git_describe_output_for_mad="$git_describe_output"
    base_tag_part=$(echo "$git_describe_output" | awk -F- '{print $1}' | sed 's/^v//')
    commits_since_tag_part=$(echo "$git_describe_output" | awk -F- '{print $2}')

    if [[ "$base_tag_part" == *"g"* ]]; then
        calculated_short_version_string="0.1.0"
    elif [[ "$commits_since_tag_part" =~ ^[0-9]+$ ]]; then
        calculated_short_version_string="${base_tag_part}.${commits_since_tag_part}"
    else
        calculated_short_version_string="${base_tag_part}.0"
    fi

    current_git_commit_count=$(git rev-list HEAD --count 2>/dev/null)
    if [[ -n "$current_git_commit_count" && "$current_git_commit_count" =~ ^[0-9]+$ ]]; then
        git_commit_count="$current_git_commit_count"
    else
        echo "⚠️ Warning: Unable to fetch git commit count. Using fallback '0'."
        git_commit_count="0"
    fi
    
    git_exact_tag_with_v=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    git_exact_tag_no_v=$(echo "$git_exact_tag_with_v" | sed 's/^v//')
    git_commit_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    git_branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    is_dirty_output=$(git status --porcelain 2>/dev/null)
fi

# --- Version Override ---
# If OVERRIDE_VERSION is set in the configuration, use it.
if [[ -n "${OVERRIDE_VERSION:-}" ]]; then
    echo "✅ Using override version: $OVERRIDE_VERSION"
    calculated_short_version_string="$OVERRIDE_VERSION"
fi

git_is_dirty="false"
if [[ -n "$is_dirty_output" ]]; then
    git_is_dirty="true"
    # Only append -DEV if not using an override version
    if [[ -z "${OVERRIDE_VERSION:-}" ]]; then
        calculated_short_version_string+="-DEV"
    fi
fi

# --- Build Counter ---
echo "⚙️ Updating local build counter from $MAD_META_PLIST_PATH..."
build_counter_val=$(print_plist_value "Print :MADBuildNumber" "$MAD_META_PLIST_PATH")
if ! [[ "$build_counter_val" =~ ^[0-9]+$ ]]; then
    build_counter_val=0
fi
build_counter=$((build_counter_val + 1))

# --- Build Date ---
build_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- Update MADMeta.plist using the robust add_or_set_plist_key function ---
echo "📝 Updating metadata in $MAD_META_PLIST_PATH..."
add_or_set_plist_key ":MADBuildDate" "$build_date" "string" "$MAD_META_PLIST_PATH"
add_or_set_plist_key ":MADBuildNumber" "$build_counter" "integer" "$MAD_META_PLIST_PATH"
add_or_set_plist_key ":MADGitCommitCount" "$git_commit_count" "integer" "$MAD_META_PLIST_PATH"
add_or_set_plist_key ":MADVersionFromTag" "$git_exact_tag_no_v" "string" "$MAD_META_PLIST_PATH"
add_or_set_plist_key ":MADGitDescribe" "$git_describe_output_for_mad" "string" "$MAD_META_PLIST_PATH"
add_or_set_plist_key ":MADGitCommitHash" "$git_commit_hash" "string" "$MAD_META_PLIST_PATH"
add_or_set_plist_key ":MADGitBranch" "$git_branch_name" "string" "$MAD_META_PLIST_PATH"
add_or_set_plist_key ":MADGitDirty" "$git_is_dirty" "string" "$MAD_META_PLIST_PATH" # "true" or "false"

# Store the applied CFBundle versions in MADMeta.plist for reference
add_or_set_plist_key ":CFBundleShortVersionString" "$calculated_short_version_string" "string" "$MAD_META_PLIST_PATH"
add_or_set_plist_key ":CFBundleVersion" "$git_commit_count" "string" "$MAD_META_PLIST_PATH" # CFBundleVersion often a string

# --- Update Target Info.plist files ---
# For these, PlistBuddy's 'Set' usually works fine for creating/updating CFBundle keys,
# as they are standard and their types are commonly strings.
# This section updates the Info.plist with the correct version numbers.
# It only sets the two standard version keys.
if [ ${#INFO_PLIST_TARGET_PATHS[@]} -gt 0 ]; then
    echo "📝 Updating CFBundle versions in target Info.plist files..."
    for plist_file in "${INFO_PLIST_TARGET_PATHS[@]}"; do
        echo "   -> $plist_file"
        set_bundle_plist_value "Set :CFBundleShortVersionString $calculated_short_version_string" "$plist_file"
        set_bundle_plist_value "Set :CFBundleVersion $git_commit_count" "$plist_file"
    done
else
    echo "ℹ️ No valid target Info.plist files found or configured to update with CFBundle versions."
fi

echo ""
echo "----------------------------------------------------"
echo "✅ Build Metadata Update Complete!"
echo "----------------------------------------------------"
echo "  Project Version (CFBundleShortVersionString): $calculated_short_version_string"
echo "  Build Number (CFBundleVersion / Git Commits): $git_commit_count"
echo "  Local Build Counter (MADBuildNumber): $build_counter"
echo "  Build Date (MADBuildDate): $build_date"
echo ""
echo "  --- Git Details (from MADMeta.plist) ---"
echo "  MADVersionFromTag: $git_exact_tag_no_v"
echo "  MADGitDescribe: $git_describe_output_for_mad"
echo "  MADGitCommitHash: $git_commit_hash"
echo "  MADGitBranch: $git_branch_name"
echo "  MADGitDirty: $git_is_dirty"
echo "----------------------------------------------------"
