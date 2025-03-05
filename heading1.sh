#!/bin/bash

if [ -f ./init-colors.sh ]
then
    . ./init-colors.sh
else
    . console-tools/init-colors.sh
fi

SUBTITLE=$*
echo -e $COLOR_HEADING1
echo -e "    $SUBTITLE"
echo -e $COLOR_RESET
