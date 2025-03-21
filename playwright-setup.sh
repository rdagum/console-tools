#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Set the default download flag to false
DOWNLOAD=false

# Check if PLAYWRIGHT_BROWSERS_PATH is set, if not, set it to the default path
if [ -z "$PLAYWRIGHT_BROWSERS_PATH" ]; then
  DOWNLOAD=true
  PLAYWRIGHT_BROWSERS_PATH="$HOME/pw-browsers"
  mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"
fi

# Define the download timestamp file path
DOWNLOAD_TIMESTAMP_FILE="$PLAYWRIGHT_BROWSERS_PATH/last_download.txt"

# Check if the download timestamp file exists
if [ ! -f "$DOWNLOAD_TIMESTAMP_FILE" ]; then
  DOWNLOAD=true
else
  # Read the date from the timestamp file and compare it with the current date
  LAST_DOWNLOAD_DATE=$(cat "$DOWNLOAD_TIMESTAMP_FILE")
  CURRENT_DATE=$(date +"%b %d %Y")
  if [ "$LAST_DOWNLOAD_DATE" != "$CURRENT_DATE" ]; then
    DOWNLOAD=true
  fi
fi

# If download is needed, install Playwright browsers
if [ "$DOWNLOAD" = true ]; then
  source ./subtitle.sh "Installing playwright browsers"
  npm -g install playwright # Step apparently not needed. Evaluate when a Chrome update is available
  npx playwright install
  date +"%b %d %Y" > "$DOWNLOAD_TIMESTAMP_FILE"
  source ./subtitle-end.sh "Done installing playwright browsers"
fi

# Exit the script
exit 0
