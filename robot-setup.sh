#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Save the current directory and change to the script's directory
pushd $(dirname $(readlink -f $BASH_SOURCE)) > /dev/null

# Source the environment variables script
source ./environment-variables.sh

# Check if the environment variables script executed successfully
if [ $? -ne 0 ]; then
  exit 1
fi

# Run the subtitle script with the message
source ./subtitle.sh "Setting up Robot Framework Requirements"

# Activate the Python virtual environment
source "$PYTHON_VENV/activate"

# Run the subtitle script for installing browser library dependencies
source ./subtitle.sh "Installing Browser library dependencies..."

# Run the Playwright setup script
source ./playwright-setup.sh

# Initialize the Robot Framework Browser library
rfbrowser init

# End the subtitle for browser library dependencies
source ./subtitle-end.sh "Done installing Browser library dependencies..."

# Deactivate the Python virtual environment
deactivate

# Return to the original directory
popd > /dev/null

