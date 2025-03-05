@echo off

setlocal
pushd %~dp0
call environment-variables.cmd
IF ERRORLEVEL 1 EXIT /B 1

IF [%*] == [] (
    set params=%ROBOT_TEST_PATH%
) ELSE (
    set params=%*
)

call subtitle.cmd Robot Tidy...

call %PYTHON_VENV%\activate.bat
IF ERRORLEVEL 1 EXIT /B 1
echo robotidy --config robotidy.toml %params%
call robotidy --config robotidy.toml %params%

popd
endlocal
exit /b 0
