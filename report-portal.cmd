@echo off

setlocal
pushd %~dp0
call environment-variables.cmd
IF ERRORLEVEL 1 EXIT /B 1

if [%REPORT_PORTAL_PROJECT_NAME%]==[] set REPORT_PORTAL_PROJECT_NAME=sandbox
if [%OUT%]==[] set OUT=output_chromium.xml
if [%ENV%]==[] set ENV=manual
if [%RP_LAUNCH_ATTRIBUTES%]==[] set RP_LAUNCH_ATTRIBUTES="%*"
if [%RP_LAUNCH_ATTRIBUTES%]==[] set RP_LAUNCH_ATTRIBUTES="attributes:none"
IF [%LAUNCH_PREFIX%]==[] set LAUNCH_PREFIX=env
IF [%LAUNCH_POSTFIX%]==[] set LAUNCH_POSTFIX=%ENV%
IF [%BUILD_URL%]==[] set BUILD_URL=null
IF [%BUILD_NUMBER%]==[] set BUILD_NUMBER=0
IF [%LAUNCH_END%]==[] set LAUNCH_END=%BUILD_NUMBER%
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
call post_report --variable RP_UUID:"%REPORT_PORTAL_UUID%" --variable RP_ENDPOINT:"%REPORT_PORTAL_URL%" --variable RP_LAUNCH:"%RP_LAUNCH%" --variable RP_PROJECT:"%REPORT_PORTAL_PROJECT_NAME%" --variable RP_LAUNCH_ATTRIBUTES:%RP_LAUNCH_ATTRIBUTES% %OUT%
IF ERRORLEVEL 1 EXIT /B 1
popd
call subtitle-end.cmd Done pushing results to Report Portal

popd
endlocal
exit /b 0
