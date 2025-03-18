#!/bin/bash
set -e
# GENERAL VARIABLES

if [ "$VARIABLES_LOADED" == "TRUE" ]
then
    exit 0
fi

pushd $(dirname $(readlink -m $BASH_SOURCE)) > /dev/null

. ./subtitle.sh "Setting up Environment Variables"
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
ROBOT_TEST_RESULTS_PATH=$BUILD_TEMP_FOLDER/robot-results/
ROBOT_TEST_PATH=$PROJECT_ROOT/automation/robot

if [ ! -f $ROBOT_TEST_RESULTS_PATH ]
then
    mkdir -p $ROBOT_TEST_RESULTS_PATH
fi

ROBOT_TESTS_PATH=$PROJECT_ROOT/automation/robot/suites/

echo PROJECT_NAME=$PROJECT_NAME
echo PROJECT_UPSTREAM_FOLDER=$PROJECT_UPSTREAM_FOLDER
echo PROJECT_ROOT=$PROJECT_ROOT
echo BUILD_FOLDER_FULL_PATH=$BUILD_FOLDER_FULL_PATH
echo BUILD_TEMP_FOLDER=$BUILD_TEMP_FOLDER
echo TEST_RESULTS_FOLDER=$TEST_RESULTS_FOLDER
echo PYTHON_VENV=$PYTHON_VENV

. ./subtitle.sh "Setting up Default Settings"

if [ "$BUILD_NUMBER" == "" ]
then
    BUILD_NUMBER=0
fi

ARTIFACTORY_DNS=ukgartifactory.jfrog.io
ARTIFACTORY_URL=https://$ARTIFACTORY_DNS/artifactory/
ARTIFACTORY_USERNAME=$USERNAME
SONAR_HOST_URL=https://sonarqube.ascentis.com

# Override settings with custom configuration for the given server
if [ -f $BUILD_FOLDER_FULL_PATH/custom-config/$computername.sh ]
then
    echo     Overriding default configuration with $computername.sh
    echo
    ./$BUILD_FOLDER_FULL_PATH/custom-config/$computername.sh
fi
# Override settings with custom configuration for the given user
if [ -f $BUILD_FOLDER_FULL_PATH/custom-config/$username.sh ]
then
    echo     Overriding default configuration with $username.sh
    echo
    ./$BUILD_FOLDER_FULL_PATH/custom-config/$username.sh
fi

echo ARTIFACTORY_URL=$ARTIFACTORY_URL
echo ARTIFACTORY_USERNAME=$ARTIFACTORY_USERNAME
echo SONAR_HOST_URL=$SONAR_HOST_URL

VARIABLES_LOADED=TRUE
popd > /dev/null
