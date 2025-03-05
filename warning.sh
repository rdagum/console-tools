#!/bin/bash

if [ -f ./init-colors.sh ]
then
    . ./init-colors.sh
else
    . console-tools/init-colors.sh
fi

WARN=$*
echo -e $COLOR_WARNING
echo -e "    WARN: $WARN"
echo -e $COLOR_RESET
