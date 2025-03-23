#!/bin/bash

if [ -f ./init-colors.sh ]
then
    . ./init-colors.sh
else
    . console-tools/init-colors.sh
fi

WARN=$*
printf "$COLOR_WARNING"
printf "    WARN: $WARN\n"
printf "$COLOR_RESET\n"
