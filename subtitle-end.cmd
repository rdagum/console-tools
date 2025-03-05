setlocal
pushd %~dp0

call init-colors.cmd

set SUBTITLE=%*
echo %COLOR_LBLUE%
echo ^<^<^< %TIME%; %SUBTITLE%
echo.%COLOR_RESET%

popd
endlocal
