#!/bin/bash

# Store the script's directory and move to it
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Source environment variables
source ./environment-variables.sh
if [ $? -ne 0 ]; then
    exit 1
fi

# Check for module name parameter
MODULE_NAME=$1
if [ -z "$MODULE_NAME" ]; then
    source ./error.sh "Module Name is Missing"
    exit 1
fi

# Display subtitle
source ./subtitle.sh "Running PyTest..."

# Activate virtual environment
source "${PYTHON_VENV}/bin/activate"
if [ $? -ne 0 ]; then
    exit 1
fi

# Change to project root and run pytest
cd "$PROJECT_ROOT"
py.test --cov-config "${BUILD_FOLDER_FULL_PATH}/.coveragerc" \
        --cov "$MODULE_NAME" \
        --junitxml "${BUILD_TEMP_FOLDER}/testresults/unit-test.xml" \
        -o junit_family=xunit2

# Handle pytest exit codes (2-4 are test failures)
EXIT_CODE=$?
echo "PyTest Exit Code: $EXIT_CODE"
if [ $EXIT_CODE -ge 2 ] && [ $EXIT_CODE -lt 5 ]; then
    exit 1
fi

cd - > /dev/null

exit 0