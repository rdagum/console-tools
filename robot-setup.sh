#!/bin/bash
set -e

pushd $(dirname $(readlink -m $BASH_SOURCE))

source environment-variables.sh

./subtitle.sh Setting up Robot Framework Requirements

echo -e "\e[31mWarning: This script is not ready yet.\e[0m"
exit 1

# Install ChromeDriver.
wget -N ${ARTIFACTORY_URL}ascentis-generic/QAA/chromedriver/chromedriver_linux64-84.0.4147.30.zip -P ~/
unzip ~/chromedriver_linux64-84.0.4147.30.zip -d ~/
rm ~/chromedriver_linux64-84.0.4147.30.zip
sudo mv -f ~/chromedriver /usr/local/bin/chromedriver
sudo chown root:root /usr/local/bin/chromedriver
sudo chmod 0755 /usr/local/bin/chromedriver

# Install GeckoDriver.
wget -N ${ARTIFACTORY_URL}ascentis-generic/QAA/geckodriver/geckodriver-v0.26.0-linux64.tar.gz -P ~/
tar xvzf ~/geckodriver-v0.26.0-linux64.tar.gz -C ~/
rm ~/geckodriver-v0.26.0-linux64.tar.gz
sudo mv -f ~/geckodriver /usr/local/bin/geckodriver
sudo chown root:root /usr/local/bin/geckodriver
sudo chmod 0755 /usr/local/bin/geckodriver

popd
exit 0

