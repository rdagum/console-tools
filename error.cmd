setlocal
pushd %~dp0

call init-colors.cmd

set ERROR_MESSAGE=%*
echo.%COLOR_ERROR%
echo.    ERROR: %ERROR_MESSAGE%
echo.%COLOR_RESET%

popd
endlocal
