
setlocal

set DIRECTORY_NAME=%1
if exist %DIRECTORY_NAME% (
    rd %DIRECTORY_NAME% /S /Q
)

endlocal
