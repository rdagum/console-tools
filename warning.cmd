setlocal
pushd %~dp0

call init-colors.cmd

set WARN=%*
echo.%COLOR_WARNING%
echo     WARN: %WARN%
echo.%COLOR_RESET%

popd
endlocal
