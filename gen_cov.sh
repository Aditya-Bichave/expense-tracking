#!/bin/bash
mkdir -p coverage
echo "" > coverage/lcov.info
for dir in test/*; do
  if [ -d "$dir" ]; then
    echo "Running tests in $dir..."
    flutter test "$dir" --coverage
    if [ -f coverage/lcov.info ]; then
      cat coverage/lcov.info >> coverage/merged_lcov.info
    fi
  fi
done
