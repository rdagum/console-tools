
:: GENERAL VARIABLES
if [%VARIABLES_LOADED%]==[TRUE] exit /b 0
pushd %~dp0
call subtitle.cmd Setting up Environment Variables
pushd ..\
SET BUILD_FOLDER_FULL_PATH=%CD%
pushd ..\
set PROJECT_ROOT=%CD%
pushd ..\
set PROJECT_UPSTREAM_FOLDER=%CD%
popd
popd
popd
SET CONSOLE_TOOLS_PATH=%BUILD_FOLDER_FULL_PATH%\console-tools
SET BUILD_TEMP_FOLDER=%PROJECT_ROOT%\.temp
if not exist %BUILD_TEMP_FOLDER% md %BUILD_TEMP_FOLDER%
SET TEST_RESULTS_FOLDER=%BUILD_TEMP_FOLDER%\TestResults
call :extract_last_token %PROJECT_ROOT% \

:: PYTHON PROJECT SPECIFIC VARIABLES
SET PYTHON_VENV=%PROJECT_ROOT%\.venv\Scripts
set ROBOT_TEST_RESULTS_PATH=%BUILD_TEMP_FOLDER%\robot-results\
set ROBOT_TEST_PATH=%PROJECT_ROOT:\=/%/automation/robot
if not exist %ROBOT_TEST_RESULTS_PATH% md %ROBOT_TEST_RESULTS_PATH%
set ROBOT_TESTS_PATH=%PROJECT_ROOT:\=/%/automation/robot/suites/
SET PLAYWRIGHT_BROWSERS_PATH=%USERPROFILE%\pw-browsers

echo PROJECT_NAME=%PROJECT_NAME%
echo PROJECT_UPSTREAM_FOLDER=%PROJECT_UPSTREAM_FOLDER%
echo PROJECT_ROOT=%PROJECT_ROOT%
echo BUILD_FOLDER_FULL_PATH=%BUILD_FOLDER_FULL_PATH%
echo BUILD_TEMP_FOLDER=%BUILD_TEMP_FOLDER%
echo TEST_RESULTS_FOLDER=%TEST_RESULTS_FOLDER%
echo PYTHON_VENV=%PYTHON_VENV%

call subtitle.cmd Setting up Default Settings

if [%BUILD_NUMBER%]==[] SET BUILD_NUMBER=0
set ARTIFACTORY_DNS=ukgartifactory.jfrog.io
set ARTIFACTORY_URL=https://%ARTIFACTORY_DNS%/artifactory/
set ARTIFACTORY_USERNAME=%USERNAME%
set SONAR_HOST_URL=https://sonarqube.ascentis.com
set REPORT_PORTAL_URL=http://10.209.172.201:8080/
set REPORT_PORTAL_UUID=2d321b85-be43-44a1-9427-bd9731c184ba

:: Override settings with custom configuration for the given server
if exist %BUILD_FOLDER_FULL_PATH%\custom-config\%computername%.cmd (
    echo [31m    Overriding default configuration with %computername%.cmd
    echo.[0m
    call %BUILD_FOLDER_FULL_PATH%\custom-config\%computername%.cmd
)
:: Override settings with custom configuration for the given user
if exist %BUILD_FOLDER_FULL_PATH%\custom-config\%username%.cmd (
    echo [31m    Overriding default configuration with %username%.cmd
    echo.[0m
    call %BUILD_FOLDER_FULL_PATH%\custom-config\%username%.cmd
)

echo ARTIFACTORY_URL=%ARTIFACTORY_URL%
echo ARTIFACTORY_USERNAME=%ARTIFACTORY_USERNAME%
echo SONAR_HOST_URL=%SONAR_HOST_URL%

SET VARIABLES_LOADED=TRUE
popd

:extract_last_token
set list=%~1
set delimiter=%~2
for /F "tokens=1* delims=%delimiter%" %%f in ("%list%") do (
	if not "%%f" == "" set PROJECT_NAME=%%f
	if not "%%g" == "" call :extract_last_token "%%g" %delimiter%
)
goto :eof
