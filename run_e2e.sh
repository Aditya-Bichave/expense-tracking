#!/bin/bash
# =============================================================================
# run_e2e.sh - Unified E2E test runner for FinancialOS
# Usage: ./run_e2e.sh [--skip-build] [--skip-deps] [--headed] [--ui] [spec-file]
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E2E_DIR="${SCRIPT_DIR}/ci/e2e"
APP_ROOT="${SCRIPT_DIR}"
BUILD_DIR="${BUILD_DIR:-build/web}"

SKIP_BUILD=0
# CI installs the browser and its system libraries itself, so it passes
# --skip-deps (or sets E2E_SKIP_DEPS=1). Left on by default for local runs, where
# installing on demand is the convenience the script exists for.
SKIP_DEPS="${E2E_SKIP_DEPS:-0}"
EXTRA_ARGS=()

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --skip-build) SKIP_BUILD=1 ;;
        --skip-deps) SKIP_DEPS=1 ;;
        --headed|--ui) EXTRA_ARGS+=("$1") ;;
        *) EXTRA_ARGS+=("$1") ;;
    esac
    shift
done

echo "[DEBUG] APP_ROOT: $APP_ROOT"
echo "[DEBUG] E2E_DIR: $E2E_DIR"
echo "[DEBUG] BUILD_DIR: $BUILD_DIR"

if [ ! -d "${E2E_DIR}/node_modules" ]; then
    echo "[INFO] node_modules not found. Running npm ci..."
    (cd "$E2E_DIR" && npm ci)
fi

if [ "$SKIP_BUILD" -eq 0 ]; then
    echo ""
    echo "============================================================"
    echo " Step 1/3: Building Flutter web in deterministic E2E mode..."
    echo "============================================================"
    cd "$APP_ROOT"
    flutter build web --release --pwa-strategy=none --dart-define=E2E_MODE=true
    echo "[OK] Build complete: ${BUILD_DIR}/"
else
    echo "[SKIP] Skipping Flutter build (--skip-build)"
    if [ ! -f "${APP_ROOT}/${BUILD_DIR}/index.html" ]; then
        echo "[ERROR] No existing build found at ${APP_ROOT}/${BUILD_DIR}. Run without --skip-build first."
        exit 1
    fi
fi

echo ""
echo "============================================================"
echo " Step 2/3: Checking Playwright Chromium..."
echo "============================================================"
cd "$E2E_DIR"
if [ "$SKIP_DEPS" -eq 1 ]; then
    # `--with-deps` shells out to apt-get. On GitHub runners the Azure Ubuntu
    # mirror is frequently unreachable, and apt then retries for 15+ minutes and
    # takes the whole job's timeout with it -- which looked like the E2E suite
    # hanging, when the suite itself runs in about 45 seconds.
    echo "[SKIP] Skipping Playwright install (--skip-deps); assuming it is present"
else
    npx playwright install chromium --with-deps
fi
echo "[OK] Playwright ready."

echo ""
echo "============================================================"
echo " Step 3/3: Running E2E tests ${EXTRA_ARGS[*]}"
echo "============================================================"

export APP_BASE_URL="${APP_BASE_URL:-http://localhost:8080}"
export BUILD_DIR="../../${BUILD_DIR}"

set +e
npx playwright test "${EXTRA_ARGS[@]}"
E2E_EXIT=$?
set -e

echo ""
if [ "$E2E_EXIT" -eq 0 ]; then
    echo "[SUCCESS] All E2E tests passed!"
else
    echo "[FAILED] Some E2E tests failed. Check ${E2E_DIR}/playwright-report/"
fi

exit $E2E_EXIT
