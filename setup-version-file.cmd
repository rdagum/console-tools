@echo off

setlocal enableextensions enabledelayedexpansion
pushd %~dp0
call environment-variables.cmd
IF ERRORLEVEL 1 EXIT /B 1

call subtitle.cmd Generating Version File

pushd %PROJECT_ROOT%
if not exist .version-input GOTO :MISSING_FILE
set /p CURRENT_VERSION=<.version-input

set SUFFIX=a
if [%BRANCH_NAME%]==[master] set SUFFIX=b
:: Previsously, we had release branch publishing with SUFFIX=rc but we don't have that need
:: anymore so we directly publish the production version from the release branch
if [%BRANCH_NAME%]==[release] set SUFFIX=
if [%BRANCH_NAME%]==[production] set SUFFIX=

echo %CURRENT_VERSION%%SUFFIX%%BUILD_NUMBER% > version.txt
IF ERRORLEVEL 1 EXIT /B 1
popd

popd
endlocal

exit /b 0

:MISSING_FILE
call error.cmd Missing .version-input file
exit /b 1
