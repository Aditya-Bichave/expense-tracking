#!/bin/bash

# FinancialOS E2E Test Runner (Bash version for CI/Linux)
# Usage: ./run_e2e.sh [playwright-args]

set -e

# Change to the script's directory
cd "$(dirname "$0")"

# Load environment variables if .env exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Ensure output directory exists for screenshots
mkdir -p test-results

echo "[E2E] Running Playwright tests..."
npx playwright test "$@"
