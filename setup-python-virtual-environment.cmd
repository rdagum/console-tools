@echo off

setlocal
pushd %~dp0
call environment-variables.cmd
IF ERRORLEVEL 1 EXIT /B 1

set PROJECT_TYPE=%1
if [%PROJECT_TYPE%]==[] set PROJECT_TYPE=robot

call subtitle.cmd Setting up Python Virtual Environment

pushd %PROJECT_ROOT%
call python -m venv .venv
IF ERRORLEVEL 1 EXIT /B 1
call %PYTHON_VENV%\python -m pip install --upgrade pip
IF ERRORLEVEL 1 EXIT /B 1
@REM call pip config set global.index-url %ARTIFACTORY_URL%api/pypi/dagum-python/simple
@REM IF ERRORLEVEL 1 EXIT /B 1
popd

if not [%PIP_PRE%]==[] set INSTALL_PRE_MODULES=--pre
echo INSTALL_PRE_MODULES=%INSTALL_PRE_MODULES%

if not exist %BUILD_FOLDER_FULL_PATH%\requirements.txt call error.cmd "Missing %BUILD_FOLDER_FULL_PATH%\requirements.txt file"

call subtitle.cmd Installing Basic Python Requirements...
call %PYTHON_VENV%\python -m pip install --upgrade -r %CONSOLE_TOOLS_PATH%\requirements-%PROJECT_TYPE%.txt
IF ERRORLEVEL 1 EXIT /B 1
call subtitle.cmd Installing Project's Python Requirements...
call %PYTHON_VENV%\python -m pip install --upgrade %INSTALL_PRE_MODULES% -r %BUILD_FOLDER_FULL_PATH%\requirements.txt
IF ERRORLEVEL 1 EXIT /B 1

popd
endlocal

exit /b 0
