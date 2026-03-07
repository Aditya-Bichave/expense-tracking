@echo off
REM =============================================================================
REM  run_e2e.bat — Local E2E test runner for FinancialOS
REM  Usage: run_e2e.bat [--skip-build] [--headed] [--ui]
REM =============================================================================

setlocal EnableDelayedExpansion

set SKIP_BUILD=0
set EXTRA_ARGS=

:parse_args
if "%~1"=="" goto :done_args
if /I "%~1"=="--skip-build"  ( set SKIP_BUILD=1 & shift & goto :parse_args )
if /I "%~1"=="--headed"       ( set EXTRA_ARGS=--headed & shift & goto :parse_args )
if /I "%~1"=="--ui"           ( set EXTRA_ARGS=--ui & shift & goto :parse_args )
echo Unknown argument: %~1
goto :usage
:done_args

REM ── Resolve paths ─────────────────────────────────────────────────────────────
set SCRIPT_DIR=%~dp0
set APP_ROOT=%SCRIPT_DIR%
set E2E_DIR=%APP_ROOT%ci\e2e
set ENV_FILE=%APP_ROOT%.env

REM ── Check required files ──────────────────────────────────────────────────────
if not exist "%E2E_DIR%\.env" (
  echo [ERROR] ci\e2e\.env not found. Copy .env.example and fill in your Supabase values.
  exit /b 1
)

if not exist "%E2E_DIR%\node_modules" (
  echo [INFO] node_modules not found. Running npm install...
  cd /d "%E2E_DIR%"
  call npm install
  if errorlevel 1 ( echo [ERROR] npm install failed & exit /b 1 )
)

REM ── Load Supabase keys from root .env for the build ───────────────────────────
set SUPABASE_URL=
set SUPABASE_ANON_KEY=
if exist "%ENV_FILE%" (
  for /f "usebackq tokens=1,2 delims==" %%A in ("%ENV_FILE%") do (
    if "%%A"=="SUPABASE_URL"      set SUPABASE_URL=%%B
    if "%%A"=="SUPABASE_ANON_KEY" set SUPABASE_ANON_KEY=%%B
  )
)

if "%SUPABASE_URL%"=="" (
  echo [ERROR] SUPABASE_URL not found in .env. Cannot build Flutter web.
  exit /b 1
)
if "%SUPABASE_ANON_KEY%"=="" (
  echo [ERROR] SUPABASE_ANON_KEY not found in .env. Cannot build Flutter web.
  exit /b 1
)

REM ── Step 1: Flutter web build (skippable) ────────────────────────────────────
if "%SKIP_BUILD%"=="0" (
  echo.
  echo ============================================================
  echo  Step 1/3: Building Flutter web...
  echo ============================================================
  cd /d "%APP_ROOT%"
  call flutter build web --release --pwa-strategy=none ^
    --dart-define=SUPABASE_URL="%SUPABASE_URL%" ^
    --dart-define=SUPABASE_ANON_KEY="%SUPABASE_ANON_KEY%"
  if errorlevel 1 ( echo [ERROR] Flutter web build failed & exit /b 1 )
  echo [OK] Build complete: build\web\
) else (
  echo [SKIP] Skipping Flutter build (--skip-build)
  if not exist "%APP_ROOT%build\web\index.html" (
    echo [ERROR] No existing build found. Run without --skip-build first.
    exit /b 1
  )
)

REM ── Step 2: Install Playwright browsers if needed ────────────────────────────
echo.
echo ============================================================
echo  Step 2/3: Checking Playwright Chromium...
echo ============================================================
cd /d "%E2E_DIR%"
call npx playwright install chromium --quiet 2>nul
echo [OK] Playwright ready.

REM ── Step 3: Run E2E tests ─────────────────────────────────────────────────────
echo.
echo ============================================================
echo  Step 3/3: Running E2E tests %EXTRA_ARGS%
echo ============================================================
cd /d "%E2E_DIR%"

REM Set environment variables explicitly for the playwright process
set E2E_SUPABASE_URL=%SUPABASE_URL%
set E2E_SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%

call npx playwright test %EXTRA_ARGS%
set E2E_EXIT=%errorlevel%

echo.
if "%E2E_EXIT%"=="0" (
  echo [SUCCESS] All E2E tests passed!
  echo To view the HTML report: cd ci\e2e ^& npm run e2e:report
) else (
  echo [FAILED] Some E2E tests failed. Check ci\e2e\playwright-report\
  echo Run: cd ci\e2e ^& npm run e2e:report
)

exit /b %E2E_EXIT%

:usage
echo.
echo Usage: run_e2e.bat [options]
echo Options:
echo   --skip-build   Skip Flutter web build (use existing build/web)
echo   --headed       Run tests in headed mode (visible browser)
echo   --ui           Open Playwright UI mode (interactive test runner)
echo.
exit /b 1
