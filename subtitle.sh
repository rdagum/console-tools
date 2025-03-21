#!/bin/bash

if [ -f ./init-colors.sh ]
then
    . ./init-colors.sh
else
    . console-tools/init-colors.sh
fi

SUBTITLE=$*
echo -e $COLOR_LBLUE
echo -e "______________________________________________________________________________________________"
echo -e "### $SUBTITLE"
echo -e $COLOR_RESET
