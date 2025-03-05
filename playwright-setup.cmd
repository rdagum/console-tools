

SET DOWNLOAD=FALSE
IF [%PLAYWRIGHT_BROWSERS_PATH%]==[] (
    SET DOWNLOAD=TRUE
    SET PLAYWRIGHT_BROWSERS_PATH=%USERPROFILE%\pw-browsers
)
SET DOWNLOAD_TIMESTAMP_FILE=%PLAYWRIGHT_BROWSERS_PATH%\last_download.txt
IF NOT EXIST %DOWNLOAD_TIMESTAMP_FILE% (
    SET DOWNLOAD=TRUE
) ELSE (
    FOR /F %%i IN (%DOWNLOAD_TIMESTAMP_FILE%) DO (
        IF "%%i" NEQ "%DATE:~4,10%%" SET DOWNLOAD=TRUE
    )

)

IF [%DOWNLOAD%] == [TRUE] (
    call subtitle.cmd Installing playwright browsers
    call npm -g install playwright // Step apparently not needed. We'll need to evaluate when a chrome update is available
    call npx playwright install
    echo %DATE:~4,10% > %DOWNLOAD_TIMESTAMP_FILE%
    call subtitle-end.cmd Done installing playwright browsers
)

REM Steps apparently not needed. We'll need to evaluate when a chrome update is available
REM SET LOCAL_BROWSERS=%PYTHON_VENV%\..\lib\site-packages\Browser\wrapper\node_modules\playwright\.local-browsers
REM IF NOT EXIST %LOCAL_BROWSERS% mklink /d %LOCAL_BROWSERS% %PLAYWRIGHT_BROWSERS_PATH%
exit /b 0
