#!/bin/bash

# Store the script's directory and move to it
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Source environment variables
source ./environment-variables.sh
if [ $? -ne 0 ]; then
    exit 1
fi

# Display subtitle
source ./subtitle.sh "Generating Version File"

# Change to project root
cd "$PROJECT_ROOT"

# Check if version input file exists
if [ ! -f .version-input ]; then
    source ./error.sh "Missing .version-input file"
    exit 1
fi

# Read current version
CURRENT_VERSION=$(cat .version-input)

# Set suffix based on branch name
SUFFIX="a"
if [ "$BRANCH_NAME" = "master" ]; then
    SUFFIX="b"
elif [ "$BRANCH_NAME" = "release" ]; then
    SUFFIX=""
elif [ "$BRANCH_NAME" = "production" ]; then
    SUFFIX=""
fi

# Generate version file
echo "${CURRENT_VERSION}${SUFFIX}${BUILD_NUMBER}" > version.txt
if [ $? -ne 0 ]; then
    exit 1
fi

cd - > /dev/null

exit 0