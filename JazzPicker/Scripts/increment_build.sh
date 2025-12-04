#!/bin/bash

# Only run during Archive (install action)
if [ "$ACTION" != "install" ]; then
    echo "Skipping build increment (not an Archive build)"
    exit 0
fi

# Path to project file
PROJECT_FILE="${PROJECT_DIR}/JazzPicker.xcodeproj/project.pbxproj"

# Get current build number
BUILD_NUM=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}")

# Increment
NEW_BUILD=$((BUILD_NUM + 1))

# Update project file (both Debug and Release configs)
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*/CURRENT_PROJECT_VERSION = $NEW_BUILD/g" "$PROJECT_FILE"

echo "Build number incremented to $NEW_BUILD"
