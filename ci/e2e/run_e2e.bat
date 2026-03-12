@echo off
REM =============================================================================
REM  run_e2e.bat - Local E2E test runner for FinancialOS
REM  Usage: run_e2e.bat [--skip-build] [--headed] [--ui] [spec-file]
REM =============================================================================

chcp 65001 > nul
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "SKIP_BUILD=0"
set "EXTRA_ARGS="
if "%BUILD_DIR%"=="" set "BUILD_DIR=build\web"

:parse_args
if "%~1"=="" goto :done_args
if /I "%~1"=="--skip-build" (
    set "SKIP_BUILD=1"
    shift
    goto :parse_args
)
if /I "%~1"=="--headed" (
    set "EXTRA_ARGS=!EXTRA_ARGS! --headed"
    shift
    goto :parse_args
)
if /I "%~1"=="--ui" (
    set "EXTRA_ARGS=!EXTRA_ARGS! --ui"
    shift
    goto :parse_args
)
set "ARG=%~1"
set "ARG=!ARG:\=/!"
set "EXTRA_ARGS=!EXTRA_ARGS! !ARG!"
shift
goto :parse_args

:done_args
set "E2E_DIR=!SCRIPT_DIR!"
if "!E2E_DIR:~-1!" neq "\" set "E2E_DIR=!E2E_DIR!\"

pushd "!E2E_DIR!..\.."
set "APP_ROOT=!cd!"
popd

echo [DEBUG] APP_ROOT: !APP_ROOT!
echo [DEBUG] E2E_DIR: !E2E_DIR!
echo [DEBUG] BUILD_DIR: !BUILD_DIR!

if not exist "!E2E_DIR!node_modules" (
    echo [INFO] node_modules not found. Running npm ci...
    cd /d "!E2E_DIR!"
    call npm.cmd ci
    if errorlevel 1 ( echo [ERROR] npm ci failed & exit /b 1 )
)

if "%SKIP_BUILD%"=="0" (
    echo.
    echo ============================================================
    echo  Step 1/3: Building Flutter web in deterministic E2E mode...
    echo ============================================================
    cd /d "!APP_ROOT!"
    call flutter build web --release --pwa-strategy=none --dart-define=E2E_MODE=true
    if errorlevel 1 ( echo [ERROR] Flutter web build failed & exit /b 1 )
    echo [OK] Build complete: !BUILD_DIR!\
) else (
    echo [SKIP] Skipping Flutter build ^(--skip-build^)
    if not exist "!APP_ROOT!\!BUILD_DIR!\index.html" (
        echo [ERROR] No existing build found. Run without --skip-build first.
        exit /b 1
    )
)

echo.
echo ============================================================
echo  Step 2/3: Checking Playwright Chromium...
echo ============================================================
cd /d "!E2E_DIR!"
call npx.cmd playwright install chromium --with-deps
if errorlevel 1 ( echo [ERROR] Playwright install failed & exit /b 1 )
echo [OK] Playwright ready.

echo.
echo ============================================================
echo  Step 3/3: Running E2E tests !EXTRA_ARGS!
echo ============================================================
if "%APP_BASE_URL%"=="" set "APP_BASE_URL=http://localhost:8080"
set "BUILD_DIR=..\..\!BUILD_DIR!"

call npx.cmd playwright test !EXTRA_ARGS!
set "E2E_EXIT=%errorlevel%"

echo.
if "%E2E_EXIT%"=="0" (
    echo [SUCCESS] All E2E tests passed!
) else (
    echo [FAILED] Some E2E tests failed. Check !E2E_DIR!playwright-report\
)

exit /b %E2E_EXIT%
