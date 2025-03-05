setlocal
pushd %~dp0

call .\console-tools\init-colors.cmd

set WARN=%*
echo.%COLOR_WARNING%
echo     WARN: %WARN%
echo.%COLOR_RESET%

popd
endlocal
