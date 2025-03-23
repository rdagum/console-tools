#!/bin/bash

if [ -f ./init-colors.sh ]
then
    . ./init-colors.sh
else
    . console-tools/init-colors.sh
fi

HEADING=$*
printf "$COLOR_HEADING1\n"
printf "    $HEADING"
printf "$COLOR_RESET\n"
