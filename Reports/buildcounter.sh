#!/bin/bash

#  buildcounter.sh
#  MAD
#
#  Created by Michael Thomason on 3/4/14.
#  Copyright © 2017 Michael Thomason. All rights reserved.

# Build Counter Script for Xcode
# This script updates version/build metadata using git information and PlistBuddy.

# Define project directory and plist paths
echo "Initializing script..."
PROJECT_DIR="${PROJECT_DIR:-/Users/michael/Desktop/Reports/Reports}"
cd "$PROJECT_DIR" || { echo "Error: Could not change to project directory $PROJECT_DIR"; exit 1; }

PLIST_PATHS=(
	"${PROJECT_DIR}/MADStack/MADDesigner/Assets/MADMeta.plist"
	"${PROJECT_DIR}/MADStack/MADDesigner/Info.plist"
)

# Validate plist files exist
for plist in "${PLIST_PATHS[@]}"; do
	if [ ! -f "$plist" ]; then
		echo "Error: Plist file not found at $plist"
		exit 1
	fi
done

# Get version and build numbers from git
echo "Fetching version and build numbers from git..."
git_tag=$(git describe --abbrev=1 --tags 2>/dev/null)
if [ -z "$git_tag" ]; then
	echo "Error: No git tags found. Ensure your repository is tagged."
	exit 1
fi

# Extract major/minor version
version=$(echo "$git_tag" | awk -F- '{print $1}' | sed 's/^v//')
minor=$(echo "$git_tag" | awk -F- '{print $2}')
minor=${minor:-0} # Default to 0 if no minor version
current_version="${version}.${minor}"

# Build number
build_number=$(git rev-list HEAD --count 2>/dev/null)
if [ -z "$build_number" ]; then
	echo "Error: Unable to fetch build number from git."
	exit 1
fi

# Increment local build counter (stored in plist)
echo "Updating build counter..."
build_counter=$(/usr/libexec/PlistBuddy -c "Print :MADBuildNumber" "${PLIST_PATHS[0]}" 2>/dev/null || echo "0")
build_counter=$((build_counter + 1))

# Set build metadata in plist files
echo "Updating plist files..."
build_date=$(date +%FT%T%Z)

for plist in "${PLIST_PATHS[@]}"; do
	/usr/libexec/PlistBuddy -c "Set :MADBuildDate $build_date" "$plist"
	/usr/libexec/PlistBuddy -c "Set :MADBuildNumber $build_counter" "$plist"
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $current_version" "$plist"
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $current_version" "$plist"
	/usr/libexec/PlistBuddy -c "Set :MADRevision $build_number" "$plist"
done

echo "Build metadata updated successfully:"
echo "  Version: $current_version"
echo "  Build Number: $build_number"
echo "  Build Counter: $build_counter"
echo "  Build Date: $build_date"
