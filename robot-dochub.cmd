@echo off

setlocal
pushd %~dp0
call environment-variables.cmd
IF ERRORLEVEL 1 EXIT /B 1

call subtitle.cmd Starting Robot Documentation Hub...

call %PYTHON_VENV%\activate.bat
IF ERRORLEVEL 1 EXIT /B 1

pushd %BUILD_TEMP_FOLDER%
start rfhub2
call rfhub2-cli --load-mode=update %ROBOT_TEST_PATH% %PROJECT_ROOT%\.venv\Lib\site-packages\CygnusLibrary
call rfhub2-cli --mode=statistics %ROBOT_TEST_PATH% %PROJECT_ROOT%\.venv\Lib\site-packages\CygnusLibrary
start chrome http://localhost:8000/
popd

popd
endlocal
exit /b 0
