#!/bin/bash

DIRECTORY_NAME=$1
if [ -d $DIRECTORY_NAME ]; then
    rm -rf $DIRECTORY_NAME
fi
