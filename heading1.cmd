setlocal
pushd %~dp0

call init-colors.cmd

set SUBTITLE=%*
echo.%COLOR_HEADING1%
echo     %SUBTITLE%
echo.%COLOR_RESET%

popd
endlocal
