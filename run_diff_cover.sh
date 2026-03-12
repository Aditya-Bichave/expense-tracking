#!/bin/bash

# Ensure coverage is up-to-date locally
flutter test test/features/reports/ --coverage

# Install diff-cover if not already installed
if ! command -v diff-cover &> /dev/null
then
    pip install diff-cover
fi

# Fetch origin main to compare against
git fetch origin main || true

# Run diff-cover
diff-cover coverage/lcov.info --compare-branch=origin/main --fail-under=80 > coverage/diff-coverage.txt
cat coverage/diff-coverage.txt
