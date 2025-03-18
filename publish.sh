#!/bin/bash
DISTELLI_ENVIRONMENT=$1
DISTELLI_MANIFEST=$2
BRANCH_NAME=$3
BUILD_VERSION=$4
ENVNAME="BUILD_VERSION:"
ENVVALUE="$ENVNAME $BUILD_VERSION"

#Adding build version to manifest
sed -i "s/$ENVNAME/$ENVVALUE/" $DISTELLI_MANIFEST

#Distelli lgin
distelli login -conf "/etc/distelli.yml"

#Distelli deploy
if [ "$BRANCH_NAME" == "master" ]
then
	distelli deploy -e $DISTELLI_ENVIRONMENT -manifest $DISTELLI_MANIFEST -m "Version $BUILD_VERSION@$BRANCH_NAME" -y -nowait
else
	distelli push -manifest $DISTELLI_MANIFEST -description "Version $BUILD_VERSION@$BRANCH_NAME"
fi
