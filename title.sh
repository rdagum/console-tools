#!/bin/bash

if [ -f ./init-colors.sh ]
then
    . ./init-colors.sh
else
    . console-tools/init-colors.sh
fi

TITLE=$*
printf "$COLOR_YELLOW"
printf " ==============================================================================================\n"
printf " ### $TITLE ###\n"
printf " ==============================================================================================\n"
printf "$COLOR_RESET\n"

 