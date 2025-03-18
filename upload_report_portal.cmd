@echo off

setlocal
pushd %~dp0

FOR %%A IN (%*) DO (
   FOR /f "tokens=1,2 delims=:" %%G IN ("%%A") DO set %%G=%%H
)

call .\environment-variables.cmd
IF ERRORLEVEL 1 EXIT /B 1

call .\report-portal.cmd %*
IF ERRORLEVEL 1 EXIT /B 1

popd
endlocal
exit /b 0
