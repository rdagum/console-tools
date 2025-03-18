#!/bin/bash

if [ -f ./init-colors.sh ]
then
    . ./init-colors.sh
else
    . console-tools/init-colors.sh
fi

ERROR_MESSAGE=$*
echo -e $COLOR_ERROR
echo -e "    ERROR: $ERROR_MESSAGE"
echo -e $COLOR_RESET
