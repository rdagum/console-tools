#!/bin/bash
GLOBIGNORE="*"
#  ______________________________________________________________________________________________
#  Parameters
#
#  $1    environment: to specify what configuration set to load
#  $2    tags to include
#  $3    tags to exclude
#  $4    browser   googlechrome | ie
#  $5    suite: Specify the name of the suite to execute
#  $6    test: Specify the name of the test to execute

function parse()
{
    list=$1
    command=$2

    sp=' '
    IFS=', ' read -r -a array <<< "$list"

    for i in ${array[@]}
    do
        tags=$tags${sp}$command${sp}$i
    done

    echo "$tags" >> "tags.txt"
}

pushd $(dirname $(readlink -m $BASH_SOURCE))

envname=$1
if [ "$2" == "*" ]
then
    tags="--include *"
    if [ "$3" == "none" ]
    then
        echo "$tags" >> "tags.txt"
    fi
else
    tags=$tags parse $2 --include
fi
if [ ! "$3" == "none" ]
then
    tags=$tags parse $3 --exclude
fi
tags=$(<tags.txt)
rm tags.txt
browsername=$4
if [ ! "$5" == "all" ]
then
    IncludeSuite=$5
fi
if [ ! "$6" == "all" ]
then
    IncludeTest=$6
fi

source environment-variables.sh

params="--consolewidth 100 --skip broken"

if [ ! "$envname" == "" ]
then
    params="--variable EnvName:$envname $params"
fi
if [ ! "$browsername" == "" ]
then
    params="--variable Browser:$browsername $params"
fi
if [ ! "$IncludeSuite" == "" ]
then
    params="--suite $IncludeSuite $params"
fi
if [ ! "$IncludeTest" == "" ]
then
    params="--test $IncludeTest $params"
fi
if [ "$IncludeSuite$IncludeTest$parallel" == "" ]
then
    parallel=TRUE
fi

params="--variable ROBOT_TEST_PATH:$ROBOT_TEST_PATH $params"

PATH=$PYTHON_VENV:$PYTHON27_PATH:$PYTHON_SCRIPTS_PATH:$WEB_DRIVERS_PATH:$PATH
LOG=log_$browsername.html
REP=report_$browsername.html
OUT=output_$browsername.xml
XUN=xunit_$browsername.xml
REPORTS_PARAMS="--log $LOG --report $REP --output $OUT --xunit $XUN"

if [ ! "$rerun" == "" ]
then
    params="--rerunfailed $ROBOT_TEST_RESULTS_PATH$OUT $params"
else
    rm -rf $ROBOT_TEST_RESULTS_PATH*.* /s /q /f || true
fi

./subtitle.sh Executing Robot e2e Tests

pushd $ROBOT_TEST_RESULTS_PATH

if [ ! "$parallel" == "TRUE" ]
then
    pabot --processes 3 $tags --exclude broken $params $REPORTS_PARAMS $ROBOT_TESTS_PATH
else
    robot $tags $params $REPORTS_PARAMS $ROBOT_TESTS_PATH
fi

popd
popd
