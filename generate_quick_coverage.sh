#!/bin/bash
# Generate coverage by running test directories individually and merging them
mkdir -p coverage_reports
dirs=$(find test -maxdepth 1 -mindepth 1 -type d)

# Since we just want to know total executable lines, we can run just one test file
# with --coverage. It won't give accurate coverage but might give total lines if we
# use a trick, but flutter test only reports on lines hit in the tested files usually
# wait, flutter test --coverage generates a report for all files if we have them all
# imported.
# We don't have to do that if we just need an estimate.
# Total lines = 65k (including comments). Executable lines is usually ~50-60% of that. So maybe 30k executable lines.
# 10% is about 3000 lines.
