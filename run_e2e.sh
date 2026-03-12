#!/bin/bash
# =============================================================================
# run_e2e.sh - Unified E2E test runner for FinancialOS
# Usage: ./run_e2e.sh [--skip-build] [--headed] [--ui] [spec-file]
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E2E_DIR="${SCRIPT_DIR}/ci/e2e"
APP_ROOT="${SCRIPT_DIR}"
BUILD_DIR="${BUILD_DIR:-build/web}"

SKIP_BUILD=0
EXTRA_ARGS=()

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --skip-build) SKIP_BUILD=1 ;;
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
npx playwright install chromium --with-deps
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
