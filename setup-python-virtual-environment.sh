#!/bin/bash
set -e

pushd $(dirname $(readlink -m $BASH_SOURCE))
source environment-variables.sh

PROJECT_TYPE=$1
if [ "$PROJECT_TYPE" == "" ]
then
    PROJECT_TYPE=robot
fi
./subtitle.sh Setting up Python Virtual Environment
pushd $PROJECT_ROOT
python3 -m venv .venv

echo PYTHON_VENV=$PYTHON_VENV
$PYTHON_VENV/python3 -m pip install --upgrade pip

pip config set global.index-url ${ARTIFACTORY_URL}api/pypi/ascentis-python/simple
popd

if [ "$PIP_PRE" != "" ]
then
    INSTALL_PRE_MODULES="--pre"
fi
echo "INSTALL_PRE_MODULES=$INSTALL_PRE_MODULES"

if [ ! -f $BUILD_FOLDER_FULL_PATH/requirements.txt ]
then
    ./error.sh "Missing $BUILD_FOLDER_FULL_PATH/requirements.txt file"
fi

./subtitle.sh Installing Basic Python Requirements...
$PYTHON_VENV/python3 -m pip install --upgrade -r $CONSOLE_TOOLS_PATH/requirements-$PROJECT_TYPE.txt

./subtitle.sh "Installing Project's Python Requirements..."
$PYTHON_VENV/python3 -m pip install --upgrade $INSTALL_PRE_MODULES -r $BUILD_FOLDER_FULL_PATH/requirements.txt

popd
exit 0
