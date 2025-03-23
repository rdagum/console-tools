#!/bin/bash

# Save the current directory and change to the script's directory
pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null

# Source the init-colors.sh script to set color variables
source ./init-colors.sh

# Concatenate all arguments into a single subtitle string
SUBTITLE="$*"

# Print the subtitle with a timestamp in light blue color
printf "$COLOR_LBLUE"
printf " <<< $(date +"%T"); $SUBTITLE\n"
printf "$COLOR_RESET\n"

# Return to the original directory
popd > /dev/null
