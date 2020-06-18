#!/bin/bash
set -euo pipefail

# http://www.mokacoding.com/blog/xcodebuild-destination-options/
# https://pewpewthespells.com/blog/buildsettings.html

function full_path_of_directory() {
    local directory_name
    directory_name="$1"
    current_directory=$(pwd)
    while [[ "$(basename "$current_directory")" != "$directory_name" && ${#current_directory} -gt 1 ]]
    do
        current_directory=$(dirname "$current_directory")
    done
    if (( ${#current_directory} <= 1 ))
    then
        echo ">>> Error: Path of '$1' not found." 1>&2
        kill -9 -- $$
        exit 1
    fi
    echo "$current_directory"
}
project_directory="$(full_path_of_directory mac-branch-deep-linking)"


framework_path="$project_directory"/Frameworks
rm -Rf "$framework_path"
mkdir -p "$framework_path"

temp_path="$project_directory"/Temp
mkdir -p "$project_directory"/Temp

function exit_function() {
    rm -Rf "$temp_path"
    rm -Rf "$project_directory"/build
}
trap exit_function EXIT

# macOS:
echo ">>> Building macOS."
target_path=~/Desktop/f/macOS
xcodebuild \
    -project Branch.xcodeproj \
    -target Branch-macOS \
    -configuration Debug \
    -sdk macosx \
    -quiet \
    clean build \
    ARCHS=x86_64 \
    VALID_ARCHS=x86_64 \
    TARGET_BUILD_DIR="$framework_path"/macOS
file "$framework_path"/macOS/Branch.framework/Branch
