@echo off

setlocal
pushd %~dp0
call environment-variables.cmd
IF ERRORLEVEL 1 EXIT /B 1

if not defined OUT set OUT=output_chromium.xml
if not defined ENV set ENV=manual
if not defined RP_LAUNCH_ATTRIBUTES set RP_LAUNCH_ATTRIBUTES=%*
set "RP_LAUNCH_ATTRIBUTES=%RP_LAUNCH_ATTRIBUTES:portal_enabled:true=%"
set "RP_LAUNCH_ATTRIBUTES=%RP_LAUNCH_ATTRIBUTES:ordering:suite_order.txt=%"
if not defined RP_LAUNCH_ATTRIBUTES set RP_LAUNCH_ATTRIBUTES=attributes:none
if not defined LAUNCH_PREFIX set LAUNCH_PREFIX=env
if not defined LAUNCH_POSTFIX set LAUNCH_POSTFIX=%ENV%
if not defined BUILD_URL% set BUILD_URL=null
if not defined BUILD_NUMBER set BUILD_NUMBER=0
if not defined LAUNCH_END set LAUNCH_END=%BUILD_NUMBER%
SET RP_LAUNCH=%LAUNCH_PREFIX%_%LAUNCH_POSTFIX% buildnumber=%LAUNCH_END%

SET output_filename=%ROBOT_TEST_RESULTS_PATH%\%OUT%

IF NOT EXIST %output_filename% SET OUT=output_googlechrome.xml
SET output_filename=%ROBOT_TEST_RESULTS_PATH%%OUT%

IF NOT EXIST %output_filename% SET OUT=output_firefox.xml
SET output_filename=%ROBOT_TEST_RESULTS_PATH%%OUT%

IF NOT EXIST %output_filename% SET OUT=output_webkit.xml
SET output_filename=%ROBOT_TEST_RESULTS_PATH%%OUT%

call subtitle.cmd Pushing results to Report Portal; Project [%REPORT_PORTAL_PROJECT_NAME%]

call %PYTHON_VENV%\activate.bat
IF ERRORLEVEL 1 EXIT /B 1

echo RP_ENDPOINT: %REPORT_PORTAL_URL%
echo RP_LAUNCH: %RP_LAUNCH%
echo RP_LAUNCH_ATTRIBUTES: %RP_LAUNCH_ATTRIBUTES%
echo Report File: %OUT%

pushd %ROBOT_TEST_RESULTS_PATH%
call post_report --variable RP_API_KEY:%REPORT_PORTAL_API_KEY% --variable RP_ENDPOINT:%REPORT_PORTAL_URL% --variable RP_LAUNCH:%RP_LAUNCH% --variable RP_PROJECT:"%REPORT_PORTAL_PROJECT_NAME%" --variable "RP_LAUNCH_ATTRIBUTES:%RP_LAUNCH_ATTRIBUTES%"  --variable verify_ssl:false %OUT%

IF ERRORLEVEL 1 EXIT /B 1
popd
call subtitle-end.cmd Done pushing results to Report Portal

popd
endlocal
exit /b 0
