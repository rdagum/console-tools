#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Save the current directory and change to the script's directory
pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null

# Function to parse tags
parsetags() {
  local list="$1"
  local command="$2"
  IFS=',' read -ra ADDR <<< "$list"
  for tag in "${ADDR[@]}"; do
    if [ -n "$tag" ]; then
      tags="$tags $command $tag"
    fi
  done
}

# Function to parse variables
parsevars() {
  local list="$1"
  local command="$2"
  IFS=',' read -ra ADDR <<< "$list"
  for var in "${ADDR[@]}"; do
    if [ -n "$var" ]; then
      vars="$vars $command $var"
    fi
  done
  vars="${vars//$/=}"
}


# Parse command-line arguments and set environment variables
for arg in "$@"; do
  IFS=':' read -r key value <<< "$arg"
  export "$key"="$value"
done

# Set default environment variables if not already set
env="${env:-ci}"
BRANCH_NAME="${BRANCH_NAME:-PD-XXXXXXX}"
mobile_device="${mobile_device:-unknown}"
mobile_app="${mobile_app:-unknown}"
browser="${browser:-chromium}"
excludetags="${excludetags:-none}"

# Adjust environment based on branch name
case "$BRANCH_NAME" in
  master) env="ci" ;;
  release) env="rc" ;;
  production) env="hf" ;;
esac

# Override environment if ROBOT_TARGET_ENV_PARAM is set
if [ -n "$ROBOT_TARGET_ENV_PARAM" ]; then
  env="$ROBOT_TARGET_ENV_PARAM"
fi

# Adjust tags based on mode
case "$mode" in
  quick) excludetags="slow,tofix,load" ;;
  regression) excludetags="tofix,load" ;;
esac

# Parse extra variables
vars=""
if [ -n "$EXTRA_VARIABLES" ]; then
  parsevars "$EXTRA_VARIABLES" --variable
fi

# Parse include and exclude tags
tags=""
if [ -n "$includetags" ]; then
  parsetags "$includetags" --include
fi
parsetags "$excludetags" --exclude

# Set ordering and resource file parameters
ordering_param=""
if [ -n "$ordering" ]; then
  ordering_param="--ordering ${ROBOT_TESTS_PATH}${ordering}"
fi

resourcefile_param=""
if [ -n "$resourcefile" ]; then
  resourcefile_param="--resourcefile ${ROBOT_TEST_PATH}/settings/${resourcefile}"
fi

# Set parameters for Robot Framework
params="--consolewidth 100 --skip broken"
params+=" --variable EnvName:$env"
params+=" --variable Browser:$browser"
params+=" --variable MobileApp:$mobile_app"
params+=" --variable MobileDevice:$mobile_device"

if [ "$trace" == "true" ]; then
  params+=" --loglevel trace"
fi
if [ -n "$suite" ]; then
  params+=" --suite $suite"
fi
if [ -n "$test" ]; then
  params+=" --test $test"
fi

threads="${threads:-3}"
params+=" --variable ROBOT_TEST_PATH:$ROBOT_TEST_PATH"

# Set PATH
export PATH="$PYTHON27_PATH:$PYTHON_SCRIPTS_PATH:$WEB_DRIVERS_PATH:$PATH"

# Set test metrics file
if [ "$mobile_app" == "unknown" ]; then
  test_metrics_file="test_metrics.html"
else
  test_metrics_file="${mobile_app}_${mobile_device}_test_metrics.html"
fi

# Set log, report, output, and xunit file names
LOG="log_${browser}.html"
REP="report_${browser}.html"
OUT="output_${browser}.xml"
XUN="xunit_${browser}.xml"

if [ "$mobile_app" != "unknown" ] && [ "$mobile_device" != "unknown" ]; then
  LOG="${mobile_app}_${mobile_device}_log_${browser}.html"
  REP="${mobile_app}_${mobile_device}_report_${browser}.html"
  OUT="${mobile_app}_${mobile_device}_output_${browser}.xml"
  XUN="${mobile_app}_${mobile_device}_xunit_${browser}.xml"
fi

REPORTS_PARAMS="--log $LOG --report $REP --output $OUT --xunit $XUN"

# Handle rerun parameter
if [ -n "$rerun" ]; then
  params+=" --rerunfailed ${ROBOT_TEST_RESULTS_PATH}${OUT}"
else
  if [ "$mobile_device" == "unknown" ]; then
    rm -rf "${ROBOT_TEST_RESULTS_PATH}"*
  fi
fi

# Display configuration
echo "Environment: $env"
echo "Tags: $tags"
echo "Browser: $browser"
echo "Suite: $suite"
echo "Test: $test"
echo "Threads: $threads"
echo

# Enable pushing results to Report Portal
if [[ "$report_portal" == "true" && "$BRANCH_NAME" != PR-* ]]; then
  portal_enabled=true
  portal_params="--listener robotframework_reportportal.listener"
  portal_params+=" --variable RP_API_KEY:\"$REPORT_PORTAL_API_KEY\""
  portal_params+=" --variable RP_ENDPOINT:\"$REPORT_PORTAL_URL\""
  portal_params+=" --variable RP_LAUNCH:\"env_$env\""
  portal_params+=" --variable RP_PROJECT:\"$REPORT_PORTAL_PROJECT_NAME\""
  portal_params+=" --variable RP_LAUNCH_ATTRIBUTES:\"$*\""
fi

# Run Robot Framework tests
pushd "$ROBOT_TEST_RESULTS_PATH" > /dev/null
if [ "$threads" -gt 1 ]; then
  echo "Running Robot with $threads threads..."
  pabot --artifacts png --artifactsinsubfolders --pabotlib --pabotlibport 0 --processes "$threads" $ordering_param $resourcefile_param $tags $vars $params $REPORTS_PARAMS "$ROBOT_TESTS_PATH"
else
  echo "Running Robot in single thread..."
  echo ROBOT_TESTS_PATH $ROBOT_TESTS_PATH
  robot $tags $vars $params $REPORTS_PARAMS $portal_params "$ROBOT_TESTS_PATH" || true
fi
popd > /dev/null

# Call report portal if enabled
if [ "$portal_enabled" == "true" ]; then
  source ./report-portal.sh 
fi

# Generate local metrics report
source ./subtitle.sh "Generating local metrics report"
robotmetrics --inputpath "$ROBOT_TEST_RESULTS_PATH" --output "$OUT" --log "$LOG" -M "$test_metrics_file"
source ./subtitle-end.sh "Done generating local metrics report"

exit 0
