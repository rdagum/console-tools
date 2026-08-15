@echo off

setlocal
pushd %~dp0

FOR %%A IN (%*) DO (
   FOR /f "tokens=1,2 delims=:" %%G IN ("%%A") DO set %%G=%%H
)

if [%BRANCH_NAME%%env%]==[master] set env=ci
if [%BRANCH_NAME%%env%]==[release] set env=rc
if [%BRANCH_NAME%%env%]==[production] set env=hf
if not [%ROBOT_TARGET_ENV_PARAM%]==[] set env=%ROBOT_TARGET_ENV_PARAM%
if [%env%]==[] set env=ci
if [%BRANCH_NAME%]==[] set BRANCH_NAME=PD-XXXXXXX
if [%mobile_device%]==[] set mobile_device=unknown
if [%mobile_app%]==[] set mobile_app=unknown

if [%browser%]==[] set browser=chromium
if [%excludetags%]==[] set excludetags=none

if [%mode%]==[quick] (
    set excludetags="slow,tofix,load"
)
if [%mode%]==[regression] (
    set excludetags="tofix,load"
)

if not "%EXTRA_VARIABLES%"=="" (
    set vars=
    call :parsevars "%EXTRA_VARIABLES%" --variable
)

if not [%includetags%]==[] (
    set tags=
    call :parsetags %includetags% --include
)
call :parsetags %excludetags% --exclude

if not [%ordering%]==[] (
    set ordering=--ordering %ROBOT_TESTS_PATH%%ordering%
)

if not [%resourcefile%]==[] (
    set resourcefile=--resourcefile %ROBOT_TEST_PATH%/settings/%resourcefile%
)

set params=--consolewidth 100 --skip broken
set params=--variable EnvName:%env% %params%
set params=--variable Browser:%browser% %params%
set params=--variable MobileApp:%mobile_app% %params%
set params=--variable MobileDevice:%mobile_device% %params%

if [%trace%] == [true] set params=--loglevel trace %params%
if not [%suite%]==[] set params=--suite %suite% %params%
if not [%test%]==[] set params=--test %test% %params%

if [%threads%]==[] set threads=3
set params=--variable ROBOT_TEST_PATH:%ROBOT_TEST_PATH% %params%

set PATH=%PYTHON27_PATH%;%PYTHON_SCRIPTS_PATH%;%WEB_DRIVERS_PATH%;%PATH%

if [%mobile_app%]==[unknown] (
    set test_metrics_file=test_metrics.html
    ) else (
        set test_metrics_file=%mobile_app%_%mobile_device%_test_metrics.html
    )

set LOG=log_%browser%.html
set REP=report_%browser%.html
set OUT=output_%browser%.xml
set XUN=xunit_%browser%.xml

if not [%mobile_app%]==[unknown] (
    if not [%mobile_device%]==[unknown] (
        set LOG=%mobile_app%_%mobile_device%_log_%browser%.html
        set REP=%mobile_app%_%mobile_device%_report_%browser%.html
        set OUT=%mobile_app%_%mobile_device%_output_%browser%.xml
        set XUN=%mobile_app%_%mobile_device%_xunit_%browser%.xml
    )
)

set REPORTS_PARAMS=--log %LOG% --report %REP% --output %OUT% --xunit %XUN% --outputdir %ROBOT_TEST_RESULTS_PATH%
if not [%rerun%]==[] (
    set params=--rerunfailed %ROBOT_TEST_RESULTS_PATH%%OUT% %params%
) else (
    if [%mobile_device%]==[unknown] (
        del %ROBOT_TEST_RESULTS_PATH%*.* /s /q /f
    )
)

echo Environment: %env%
echo Tags: %tags%
echo Browser: %browser%
echo Suite: %suite%
echo Test: %test%
echo Threads: %threads%
echo.

:: Enable pushing results from Jenkins to Report Portal when the branch is not a Pull Request (PR-)
if x%REPORT_PORTAL%_%BRANCH_NAME:-=%==xtrue_%BRANCH_NAME% (
    set portal_enabled=true
    set portal_params=--listener robotframework_reportportal.listener --variable RP_UUID:"%REPORT_PORTAL_UUID%" --variable RP_ENDPOINT:"%REPORT_PORTAL_URL%" --variable RP_LAUNCH:"env_%ENV%" --variable RP_PROJECT:"%REPORT_PORTAL_PROJECT_NAME%" --variable RP_LAUNCH_ATTRIBUTES:"%*"
)

:: Run Robot Framework tests. The runners are invoked through subroutines so
:: %ERRORLEVEL% is read outside a parenthesized block (inside one it would be
:: expanded at parse time, before the tool has run). The exit code is kept and
:: propagated at the very end, after the reports are produced.
set ROBOT_EXIT_CODE=0
pushd %PROJECT_ROOT%
if %threads% gtr 1 (call :run_pabot) else (call :run_robot)
popd

if [%portal_enabled%] == [true] (
    call report-portal.cmd %*
)

:: Post-processing only warns on failure so a broken report never turns a green
:: run red - or a red run green.
call subtitle.cmd Generating local metrics report
robotmetrics --inputpath %ROBOT_TEST_RESULTS_PATH% --output %OUT% --log %LOG% -M %test_metrics_file% || call warning.cmd robotmetrics failed - skipping the local metrics report
call subtitle-end.cmd Done generating local metrics report

:: Report and propagate the Robot exit code: entry scripts (and CI) rely on this
:: to tell a passing run from a failing one.
echo.
if "%ROBOT_EXIT_CODE%" == "0" (
    call subtitle-end.cmd All Robot tests passed
) else (
    call error.cmd Some Robot tests failed - exit code %ROBOT_EXIT_CODE%
)

popd
endlocal & exit /B %ROBOT_EXIT_CODE%

:run_pabot
echo Running Robot with %threads% threads...
echo.
call pabot --artifacts png --artifactsinsubfolders --pabotlib --pabotlibport 0 --processes %threads% %ordering% %resourcefile% %tags% %vars% %params% %REPORTS_PARAMS% %ROBOT_TESTS_PATH%
set ROBOT_EXIT_CODE=%ERRORLEVEL%
goto :eof

:run_robot
echo Running Robot in single thread...
echo.
call robot %tags% %vars% %params% %REPORTS_PARAMS% %ROBOT_TESTS_PATH%
set ROBOT_EXIT_CODE=%ERRORLEVEL%
goto :eof

:parsetags
set list=%~1
set command=%~2
for /F "tokens=1* delims=," %%f in ("%list%") do (
    if not "%%f" == "" set tags=%tags% %command% %%f
    if not "%%g" == "" call :parsetags "%%g" %command%
)
goto :eof

:parsevars
set list=%~1
set command=%~2
for /F "tokens=1* delims=," %%f in ("%list%") do (
    if not "%%f" == "" set vars=%vars% %command% %%f
    if not "%%g" == "" call :parsevars "%%g" %command%
)
set vars=%vars:$=:%
goto :eof

popd
endlocal
