#!/bin/bash

DIRECTORY_NAME=$1
if [ !-d $DIRECTORY_NAME ]; then
    mkdir $DIRECTORY_NAME
fi
