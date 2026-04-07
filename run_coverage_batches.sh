#!/bin/bash
# Find all test files
find test -name "*_test.dart" > all_tests.txt
split -l 50 all_tests.txt batch_

mkdir -p coverage_parts
count=0
for batch in batch_*; do
  count=$((count+1))
  echo "Running batch $count..."
  flutter test $(cat $batch) --coverage
  mv coverage/lcov.info "coverage_parts/lcov_$count.info" 2>/dev/null || true
done

# We don't have lcov installed? We can use a simple python script to merge them.
