@echo off
REM =============================================================================
REM  run_e2e.bat — Local E2E test runner for FinancialOS
REM  Usage: run_e2e.bat [--skip-build] [--headed] [--ui] [spec-file]
REM =============================================================================

chcp 65001 > nul
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set SKIP_BUILD=0
set EXTRA_ARGS=

:parse_args
if "%~1"=="" goto :done_args
if /I "%~1"=="--skip-build" (
    set SKIP_BUILD=1
    shift
    goto :parse_args
)
if /I "%~1"=="--headed" (
    set EXTRA_ARGS=!EXTRA_ARGS! --headed
    shift
    goto :parse_args
)
if /I "%~1"=="--ui" (
    set EXTRA_ARGS=!EXTRA_ARGS! --ui
    shift
    goto :parse_args
)
REM Add any other arguments directly to Playwright
set EXTRA_ARGS=!EXTRA_ARGS! %1
shift
goto :parse_args
:done_args

REM ── Resolve paths ─────────────────────────────────────────────────────────────
set "E2E_DIR=!SCRIPT_DIR!"
REM Ensure E2E_DIR has a trailing backslash
if "!E2E_DIR:~-1!" neq "\" set "E2E_DIR=!E2E_DIR!\"

echo [DEBUG] SCRIPT_DIR: !SCRIPT_DIR!
echo [DEBUG] E2E_DIR: !E2E_DIR!

pushd "!E2E_DIR!..\.."
set "APP_ROOT=!cd!\"
popd

echo [DEBUG] APP_ROOT: !APP_ROOT!

set "E2E_ENV=!E2E_DIR!.env"
set "ROOT_ENV=!APP_ROOT!.env"

REM ── Check required files ──────────────────────────────────────────────────────
if not exist "!E2E_ENV!" (
    echo [ERROR] !E2E_ENV! not found.
    echo Copy .env.example to .env in ci\e2e\ and fill in your values.
    exit /b 1
)

if not exist "!E2E_DIR!node_modules" (
    echo [INFO] node_modules not found. Running npm install...
    cd /d "!E2E_DIR!"
    call npm install
    if errorlevel 1 ( echo [ERROR] npm install failed & exit /b 1 )
)

REM ── Load Supabase keys from root .env for the build ───────────────────────────
set "SUPABASE_URL="
set "SUPABASE_ANON_KEY="
if exist "!ROOT_ENV!" (
    for /f "usebackq tokens=1,2 delims==" %%A in ("!ROOT_ENV!") do (
        set "key=%%A"
        set "val=%%B"
        if "!key!"=="SUPABASE_URL"      set "SUPABASE_URL=!val!"
        if "!key!"=="SUPABASE_ANON_KEY" set "SUPABASE_ANON_KEY=!val!"
    )
)

if "%SUPABASE_URL%"=="" (
    echo [ERROR] SUPABASE_URL not found in !ROOT_ENV!. Cannot build Flutter web.
    exit /b 1
)
if "%SUPABASE_ANON_KEY%"=="" (
    echo [ERROR] SUPABASE_ANON_KEY not found in !ROOT_ENV!. Cannot build Flutter web.
    exit /b 1
)

REM ── Step 1: Flutter web build (skippable) ────────────────────────────────────
if "%SKIP_BUILD%"=="0" (
    echo.
    echo ============================================================
    echo  Step 1/3: Building Flutter web...
    echo ============================================================
    cd /d "!APP_ROOT!"
    call flutter build web --release --pwa-strategy=none ^
        --dart-define=SUPABASE_URL="%SUPABASE_URL%" ^
        --dart-define=SUPABASE_ANON_KEY="%SUPABASE_ANON_KEY%"
    if errorlevel 1 ( echo [ERROR] Flutter web build failed & exit /b 1 )
    echo [OK] Build complete: build\web\
) else (
    echo [SKIP] Skipping Flutter build (--skip-build)
    if not exist "!APP_ROOT!build\web\index.html" (
        echo [ERROR] No existing build found. Run without --skip-build first.
        exit /b 1
    )
)

REM ── Step 2: Install Playwright browsers if needed ────────────────────────────
echo.
echo ============================================================
echo  Step 2/3: Checking Playwright Chromium...
echo ============================================================
cd /d "!E2E_DIR!"
call npx playwright install chromium --quiet 2>nul
echo [OK] Playwright ready.

REM ── Step 3: Run E2E tests ─────────────────────────────────────────────────────
echo.
echo ============================================================
echo  Step 3/3: Running E2E tests !EXTRA_ARGS!
echo ============================================================
cd /d "!E2E_DIR!"

REM Set environment variables explicitly for the playwright process
set "E2E_SUPABASE_URL=%SUPABASE_URL%"
set "E2E_SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%"

call npx playwright test !EXTRA_ARGS!
set E2E_EXIT=%errorlevel%

echo.
if "%E2E_EXIT%"=="0" (
    echo [SUCCESS] All E2E tests passed!
) else (
    echo [FAILED] Some E2E tests failed. Check !E2E_DIR!playwright-report\
)

exit /b %E2E_EXIT%
