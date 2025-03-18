
setlocal

set DIRECTORY_NAME=%1
if not exist %DIRECTORY_NAME% (
    md %DIRECTORY_NAME%
)

endlocal
