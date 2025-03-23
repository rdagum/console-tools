#!/bin/bash

if [ -f ./init-colors.sh ]
then
    . ./init-colors.sh
else
    . console-tools/init-colors.sh
fi

SUBTITLE=$*
printf "$COLOR_LBLUE ______________________________________________________________________________________________ \n"
printf " ### $SUBTITLE\n"
printf "$COLOR_RESET\n"
