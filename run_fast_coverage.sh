#!/bin/bash
# Find all test files and run them in batches to generate a full lcov.info without timing out.
# Or just use the test script in the repo if it exists.
if [ -f "run_tests_ci.sh" ]; then
  cat run_tests_ci.sh
fi
