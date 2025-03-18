
setlocal
pushd %~dp0
call environment-variables.cmd
IF ERRORLEVEL 1 EXIT /B 1

SET MODULE_NAME=%1
IF [%MODULE_NAME%] == [] call error.cmd Module Name is Missing

call subtitle.cmd Running PyTest...

call %PYTHON_VENV%\activate.bat
IF ERRORLEVEL 1 EXIT /B 1

pushd %PROJECT_ROOT%
call py.test --cov-config %BUILD_FOLDER_FULL_PATH%\.coveragerc --cov %MODULE_NAME% --junitxml %BUILD_TEMP_FOLDER%\testresults\unit-test.xml -o junit_family=xunit2
echo PyTest Exit Code: %ERRORLEVEL%
IF ERRORLEVEL 2 (
    IF NOT ERRORLEVEL 5 EXIT /B 1
)
popd

endlocal

exit /b 0
