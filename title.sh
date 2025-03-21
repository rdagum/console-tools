#!/bin/bash

if [ -f ./init-colors.sh ]
then
    . ./init-colors.sh
else
    . console-tools/init-colors.sh
fi

TITLE=$*
echo -e $COLOR_YELLOW
echo -e "=============================================================================================="
echo -e "### $TITLE ###"
echo -e "=============================================================================================="
echo -e $COLOR_RESET
echo -e "."
