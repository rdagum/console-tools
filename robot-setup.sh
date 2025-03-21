#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Save the current directory and change to the script's directory
pushd $(dirname $(readlink -f $BASH_SOURCE))

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
rfbrowser init --skip-browsers

# End the subtitle for browser library dependencies
./subtitle-end.sh "Done installing Browser library dependencies..."

# Check if any command failed
if [ $? -ne 0 ]; then
  exit 1
fi

# Deactivate the Python virtual environment
deactivate

# Return to the original directory
popd > /dev/null

exit 0

# # Install ChromeDriver.
# wget -N ${ARTIFACTORY_URL}ascentis-generic/QAA/chromedriver/chromedriver_linux64-84.0.4147.30.zip -P ~/
# unzip ~/chromedriver_linux64-84.0.4147.30.zip -d ~/
# rm ~/chromedriver_linux64-84.0.4147.30.zip
# sudo mv -f ~/chromedriver /usr/local/bin/chromedriver
# sudo chown root:root /usr/local/bin/chromedriver
# sudo chmod 0755 /usr/local/bin/chromedriver

# # Install GeckoDriver.
# wget -N ${ARTIFACTORY_URL}ascentis-generic/QAA/geckodriver/geckodriver-v0.26.0-linux64.tar.gz -P ~/
# tar xvzf ~/geckodriver-v0.26.0-linux64.tar.gz -C ~/
# rm ~/geckodriver-v0.26.0-linux64.tar.gz
# sudo mv -f ~/geckodriver /usr/local/bin/geckodriver
# sudo chown root:root /usr/local/bin/geckodriver
# sudo chmod 0755 /usr/local/bin/geckodriver


