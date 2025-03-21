#!/bin/bash

# Save the current directory and change to the script's directory
pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null

# Source the init-colors.sh script to set color variables
source ./init-colors.sh

# Concatenate all arguments into a single subtitle string
SUBTITLE="$*"

# Print the subtitle with a timestamp in light blue color
echo -e "${COLOR_LBLUE}"
echo -e "<<< $(date +"%T"); $SUBTITLE"
echo -e "${COLOR_RESET}"

# Return to the original directory
popd > /dev/null

exit 0
