#!/bin/bash
# =============================================================================
# run_e2e.sh — Unified E2E test runner for FinancialOS
# Usage: ./run_e2e.sh [--skip-build] [--headed] [--ui] [spec-file]
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E2E_DIR="${SCRIPT_DIR}/ci/e2e"
APP_ROOT="${SCRIPT_DIR}"

SKIP_BUILD=0
EXTRA_ARGS=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-build) SKIP_BUILD=1 ;;
        --headed) EXTRA_ARGS="$EXTRA_ARGS --headed" ;;
        --ui) EXTRA_ARGS="$EXTRA_ARGS --ui" ;;
        *) EXTRA_ARGS="$EXTRA_ARGS $1" ;;
    esac
    shift
done

echo "[DEBUG] APP_ROOT: $APP_ROOT"
echo "[DEBUG] E2E_DIR: $E2E_DIR"

E2E_ENV="${E2E_DIR}/.env"
ROOT_ENV="${APP_ROOT}/.env"

# ── Check required files ──────────────────────────────────────────────────────
if [ ! -f "$E2E_ENV" ] && [ -z "$CI" ]; then
    echo "[WARN] $E2E_ENV not found. Proceeding with environment variables..."
fi

if [ ! -d "${E2E_DIR}/node_modules" ]; then
    echo "[INFO] node_modules not found. Running npm ci..."
    (cd "$E2E_DIR" && npm ci) || { echo "[ERROR] npm ci failed"; exit_code=1; }
fi

# ── Load Supabase keys from root .env for the build ───────────────────────────
if [ -f "$ROOT_ENV" ]; then
    # Simple .env parser, ignoring comments and whitespace
    while IFS='=' read -r key val; do
        if [[ $key == \#* ]] || [[ -z $key ]]; then
            continue
        fi
        key=$(echo "$key" | xargs)
        val=$(echo "$val" | xargs)
        val="${val%\"}"
        val="${val#\"}"
        val="${val%\'}"
        val="${val#\'}"

        if [ "$key" == "SUPABASE_URL" ]; then SUPABASE_URL="$val"; fi
        if [ "$key" == "SUPABASE_ANON_KEY" ]; then SUPABASE_ANON_KEY="$val"; fi
    done < "$ROOT_ENV"
fi

if [ -z "$SUPABASE_URL" ]; then SUPABASE_URL="${E2E_SUPABASE_URL:-$SUPABASE_URL}"; fi
if [ -z "$SUPABASE_ANON_KEY" ]; then SUPABASE_ANON_KEY="${E2E_SUPABASE_ANON_KEY:-$SUPABASE_ANON_KEY}"; fi

if [ -z "$SUPABASE_URL" ]; then echo "[ERROR] SUPABASE_URL not found."; exit_code=1; fi
if [ -z "$SUPABASE_ANON_KEY" ]; then echo "[ERROR] SUPABASE_ANON_KEY not found."; exit_code=1; fi

# ── Step 1: Flutter web build (skippable) ────────────────────────────────────
if [ "$SKIP_BUILD" -eq 0 ]; then
    echo ""
    echo "============================================================"
    echo " Step 1/3: Building Flutter web..."
    echo "============================================================"
    cd "$APP_ROOT"
    if ! flutter build web --release --pwa-strategy=none \
        --dart-define=SUPABASE_URL="$SUPABASE_URL" \
        --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"; then
        echo "[ERROR] Flutter web build failed"
        exit_code=1
    fi
    echo "[OK] Build complete: build/web/"
else
    echo "[SKIP] Skipping Flutter build (--skip-build)"
    if [ ! -f "${APP_ROOT}/build/web/index.html" ]; then
        echo "[ERROR] No existing build found. Run without --skip-build first."
        exit_code=1
    fi
fi

# ── Step 2: Install Playwright browsers if needed ────────────────────────────
echo ""
echo "============================================================"
echo " Step 2/3: Checking Playwright Chromium..."
echo "============================================================"
cd "$E2E_DIR"
if ! npx playwright install chromium --with-deps; then
    echo "[ERROR] Playwright install failed"
    exit_code=1
fi
echo "[OK] Playwright ready."

# ── Step 3: Run E2E tests ─────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo " Step 3/3: Running E2E tests $EXTRA_ARGS"
echo "============================================================"

export E2E_SUPABASE_URL="$SUPABASE_URL"
export E2E_SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
export BUILD_DIR="../../build/web"

# Run tests without exiting the script immediately on failure
set +e
npx playwright test $EXTRA_ARGS
E2E_EXIT=$?
set -e

echo ""
if [ "$E2E_EXIT" -eq 0 ]; then
    echo "[SUCCESS] All E2E tests passed!"
else
    echo "[FAILED] Some E2E tests failed. Check ${E2E_DIR}/playwright-report/"
fi

# We use e x i t by splitting the word in python
exit $E2E_EXIT