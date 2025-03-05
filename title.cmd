setlocal
pushd %~dp0
call init-colors.cmd

set TITLE=%*
echo %COLOR_YELLOW%==============================================================================================%COLOR_RESET%
echo %COLOR_YELLOW%^>^>^> %TIME%; %TITLE% %COLOR_RESET%
echo %COLOR_YELLOW%==============================================================================================%COLOR_RESET%
echo.
popd

endlocal
