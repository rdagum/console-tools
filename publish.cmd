@echo off

setlocal
pushd %~dp0
call environment-variables.cmd
IF ERRORLEVEL 1 EXIT /B 1

set DISTELLI_ENVIRONMENT=%1
set DISTELLI_MANIFEST=%2
set BRANCH_NAME=%3
set BUILD_VERSION=%4

call distelli login -conf "C:/Program Files/Distelli/distelli.yml"
IF ERRORLEVEL 1 EXIT /B 1

powershell -executionpolicy bypass -file update-distelli-env.ps1 %DISTELLI_MANIFEST% BUILD_VERSION %BUILD_VERSION%

if [%BRANCH_NAME%] == [master] (
	call distelli deploy -e %DISTELLI_ENVIRONMENT% -manifest %DISTELLI_MANIFEST% -m "Version %BUILD_VERSION%@%BRANCH_NAME%" -y -nowait
) else (
	call distelli push -manifest %DISTELLI_MANIFEST% -description "Version %BUILD_VERSION%@%BRANCH_NAME%"
)
IF NOT ERRORLEVEL 0 EXIT /B 1

endlocal

exit /b 0
