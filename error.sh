#!/bin/bash

if [ -f ./init-colors.sh ]
then
    . ./init-colors.sh
else
    . console-tools/init-colors.sh
fi

ERROR_MESSAGE=$*
printf "$COLOR_ERROR"
printf "    ERROR: $ERROR_MESSAGE\n"
printf "$COLOR_RESET\n"
