@echo off

setlocal
pushd %~dp0
call environment-variables.cmd
IF ERRORLEVEL 1 EXIT /B 1

call subtitle.cmd Setting up Robot Framework Requirements

call %PYTHON_VENV%\activate.bat
call subtitle.cmd Installing Browser library dependencies...
call playwright-setup.cmd
call rfbrowser init --skip-browsers
call subtitle-end.cmd Done installing Browser library dependencies...


IF ERRORLEVEL 1 EXIT /B 1
call %PYTHON_VENV%\deactivate.bat

@REM call choco source remove -n=chocolatey
@REM call choco source add -n=ascentis-artifactory-prod -s=https://artifactory.ascentis.com/artifactory/api/nuget/ascentis-chocolatey
@REM call choco install vcredist140

popd
endlocal

exit /b 0
