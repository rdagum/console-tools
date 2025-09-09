

SET DOWNLOAD=FALSE
SET LOCAL_BROWSERS=%PYTHON_VENV%\..\lib\site-packages\Browser\wrapper\node_modules\playwright-core\.local-browsers
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
    call npm -g install playwright
    call npx playwright install
    call rfbrowser init --skip-browsers
    echo %DATE:~4,10% > %DOWNLOAD_TIMESTAMP_FILE%
    REM The SymLink below is required to allow playwright to find the browsers when running tests with F5 in VSCode or
    REM when running from the Testing section in VSCode
    rmdir "%LOCAL_BROWSERS%" /q 2>nul
    mklink /d "%LOCAL_BROWSERS%" "%PLAYWRIGHT_BROWSERS_PATH%"
    call subtitle-end.cmd Done installing playwright browsers
)

exit /b 0
