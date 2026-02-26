#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "--- 🧪 Running Unit Tests with Coverage ---"

# Run tests with coverage
flutter test --coverage

# Check if diff-cover is installed
if ! command -v diff-cover &> /dev/null
then
    echo -e "${RED}diff-cover could not be found.${NC}"
    echo "Please install it using: pip install diff-cover"
    echo "Or run tests without diff coverage checks."
    exit 1
fi

echo "--- 📊 Analyzing Diff Coverage ---"
echo "Comparing against origin/main..."

# Fetch origin/main to ensure we have the base for comparison
git fetch origin main || true

# Run diff-cover
# Fails if coverage on changed lines is < 80%
if diff-cover coverage/lcov.info --compare-branch=origin/main --fail-under=80; then
    echo -e "${GREEN}✅ Diff Coverage passed! (>= 80%)${NC}"
else
    echo -e "${RED}❌ Diff Coverage failed! (< 80%)${NC}"
    echo "Please add tests for your changes."
    exit 1
fi

echo "--- 📈 Total Coverage Summary ---"
# Simple total coverage check using lcov summary or awk
if [ -f coverage/lcov.info ]; then
    # Extract total line coverage percentage
    TOTAL_COV=$(awk -F: '/^LF:/{lf+=$2} /^LH:/{lh+=$2} END{ pct=(lf?100*lh/lf:0); printf("%.2f", pct) }' coverage/lcov.info)
    echo "Total Coverage: ${TOTAL_COV}%"

    # Check if total coverage is below threshold (e.g., 35% as per CI)
    if (( $(echo "$TOTAL_COV < 35" | bc -l) )); then
        echo -e "${RED}⚠️  Total coverage is low (< 35%). Consider adding more tests.${NC}"
        # We don't fail here locally to allow incremental improvements, but CI might fail.
    else
        echo -e "${GREEN}Total coverage is acceptable (>= 35%).${NC}"
    fi
else
    echo "coverage/lcov.info not found."
fi
