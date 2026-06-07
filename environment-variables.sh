#!/bin/bash
set -e
# GENERAL VARIABLES

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null

if [ -z "$VARIABLES_LOADED" ]; then

    source ./subtitle.sh "Setting up Environment Variables"
    pushd ../ > /dev/null
    BUILD_FOLDER_FULL_PATH=$(pwd)
    pushd ../ > /dev/null
    PROJECT_ROOT=$(pwd)
    PROJECT_NAME="${PWD##*/}"
    pushd ../ > /dev/null
    PROJECT_UPSTREAM_FOLDER=$(pwd)
    popd > /dev/null
    popd > /dev/null
    popd > /dev/null
    CONSOLE_TOOLS_PATH=$BUILD_FOLDER_FULL_PATH/console-tools
    BUILD_TEMP_FOLDER=$PROJECT_ROOT/.temp

    if [ ! -f $BUILD_TEMP_FOLDER ]
    then
        mkdir -p $BUILD_TEMP_FOLDER
    fi

    TEST_RESULTS_FOLDER=$BUILD_TEMP_FOLDER/TestResults

    # PYTHON PROJECT SPECIFIC VARIABLES
    PYTHON_VENV=$PROJECT_ROOT/.venv/bin

    # On Windows (Git Bash/MSYS) the venv ships under Scripts/, on Linux under bin/.
    if [ ! -d "$PYTHON_VENV" ] && [ -d "$PROJECT_ROOT/.venv/Scripts" ]; then
        PYTHON_VENV=$PROJECT_ROOT/.venv/Scripts
    fi

    # Robot runs under the native (Windows) Python, which cannot resolve MSYS
    # paths like /c/Users/...; convert to drive-letter form (C:/Users/...) when
    # cygpath is available, mirroring the %PROJECT_ROOT:\=/% conversion in the
    # .cmd chain. On Linux cygpath is absent and the path is used as-is.
    to_native_path() {
        if command -v cygpath > /dev/null 2>&1; then
            cygpath -m "$1"
        else
            echo "$1"
        fi
    }

    ROBOT_TEST_RESULTS_PATH="$(to_native_path "$BUILD_TEMP_FOLDER/robot-results")/"
    ROBOT_TEST_PATH="$(to_native_path "$PROJECT_ROOT/automation/robot")"

    if [ ! -d "$ROBOT_TEST_RESULTS_PATH" ]
    then
        mkdir -p "$ROBOT_TEST_RESULTS_PATH"
    fi

    ROBOT_TESTS_PATH="$(to_native_path "$PROJECT_ROOT/automation/robot/suites")/"

    echo PROJECT_NAME=$PROJECT_NAME
    echo PROJECT_UPSTREAM_FOLDER=$PROJECT_UPSTREAM_FOLDER
    echo PROJECT_ROOT=$PROJECT_ROOT
    echo ROBOT_TESTS_PATH=$ROBOT_TESTS_PATH
    echo BUILD_FOLDER_FULL_PATH=$BUILD_FOLDER_FULL_PATH
    echo BUILD_TEMP_FOLDER=$BUILD_TEMP_FOLDER
    echo TEST_RESULTS_FOLDER=$TEST_RESULTS_FOLDER
    echo PYTHON_VENV=$PYTHON_VENV

    source ./subtitle.sh "Setting up Default Settings"

    if [ "$BUILD_NUMBER" == "" ]
    then
        BUILD_NUMBER=0
    fi

    # Resolve host/user names across platforms (Linux exposes HOST/HOSTNAME/USER,
    # Windows Git Bash exposes COMPUTERNAME/USERNAME), mirroring the %computername%
    # and %username% lookups in the .cmd chain.
    CONFIG_HOST="${HOST:-${HOSTNAME:-$COMPUTERNAME}}"
    CONFIG_USER="${USER:-$USERNAME}"

    ARTIFACTORY_DNS=artifactory.jfrog.io
    ARTIFACTORY_URL=https://$ARTIFACTORY_DNS/artifactory/
    ARTIFACTORY_USERNAME=$CONFIG_USER
    SONAR_HOST_URL=https://sonarqube.dagum.me
    REPORT_PORTAL_URL=http://10.209.172.201:8080/

    # Override settings with custom configuration for the given server
    if [ -f $BUILD_FOLDER_FULL_PATH/custom-config/$CONFIG_HOST.sh ]
    then
        echo     Overriding default configuration with $CONFIG_HOST.sh
        echo
        source $BUILD_FOLDER_FULL_PATH/custom-config/$CONFIG_HOST.sh
    fi
    # Override settings with custom configuration for the given user
    if [ -f $BUILD_FOLDER_FULL_PATH/custom-config/$CONFIG_USER.sh ]
    then
        echo     Overriding default configuration with $CONFIG_USER.sh
        echo
        source $BUILD_FOLDER_FULL_PATH/custom-config/$CONFIG_USER.sh
    fi

    echo ARTIFACTORY_URL=$ARTIFACTORY_URL
    echo ARTIFACTORY_USERNAME=$ARTIFACTORY_USERNAME
    echo SONAR_HOST_URL=$SONAR_HOST_URL

    export VARIABLES_LOADED=true

fi

popd > /dev/null
