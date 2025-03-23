#!/bin/bash

set -e
pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null
source ./environment-variables.sh

: "${REPORT_PORTAL_PROJECT_NAME:=sandbox}"
: "${OUT:=output_chromium.xml}"
: "${ENV:=manual}"
: "${RP_LAUNCH_ATTRIBUTES:="$*"}"
: "${RP_LAUNCH_ATTRIBUTES:="attributes:none"}"
: "${LAUNCH_PREFIX:=env}"
: "${LAUNCH_POSTFIX:=$ENV}"
: "${BUILD_URL:=null}"
: "${BUILD_NUMBER:=0}"
: "${LAUNCH_END:=$BUILD_NUMBER}"
RP_LAUNCH="${LAUNCH_PREFIX}_${LAUNCH_POSTFIX} buildnumber=${LAUNCH_END}"

output_filename="${ROBOT_TEST_RESULTS_PATH}/${OUT}"

if [[ ! -f "$output_filename" ]]; then
  OUT="output_googlechrome.xml"
  output_filename="${ROBOT_TEST_RESULTS_PATH}/${OUT}"
fi

if [[ ! -f "$output_filename" ]]; then
  OUT="output_firefox.xml"
  output_filename="${ROBOT_TEST_RESULTS_PATH}/${OUT}"
fi

if [[ ! -f "$output_filename" ]]; then
  OUT="output_webkit.xml"
  output_filename="${ROBOT_TEST_RESULTS_PATH}/${OUT}"
fi

source ./subtitle.sh "Pushing results to Report Portal; Project [${REPORT_PORTAL_PROJECT_NAME}]"

source "$PYTHON_VENV/activate"
echo "RP_ENDPOINT: ${REPORT_PORTAL_URL}"
echo "RP_LAUNCH: ${RP_LAUNCH}"
echo "RP_LAUNCH_ATTRIBUTES: ${RP_LAUNCH_ATTRIBUTES}"
echo "Report File: ${OUT}"

pushd "${ROBOT_TEST_RESULTS_PATH}"
echo post_report --variable RP_UUID:"${REPORT_PORTAL_UUID}" --variable RP_ENDPOINT:"${REPORT_PORTAL_URL}" --variable RP_LAUNCH:"${RP_LAUNCH}" --variable RP_PROJECT:"${REPORT_PORTAL_PROJECT_NAME}" --variable RP_LAUNCH_ATTRIBUTES:"${RP_LAUNCH_ATTRIBUTES}" "${OUT}"
post_report --variable RP_UUID:"${REPORT_PORTAL_UUID}" --variable RP_ENDPOINT:"${REPORT_PORTAL_URL}" --variable RP_LAUNCH:"${RP_LAUNCH}" --variable RP_PROJECT:"${REPORT_PORTAL_PROJECT_NAME}" --variable RP_LAUNCH_ATTRIBUTES:"${RP_LAUNCH_ATTRIBUTES}" "${OUT}"
popd > /dev/null

source ./subtitle-end.sh "Done pushing results to Report Portal"

popd > /dev/null

