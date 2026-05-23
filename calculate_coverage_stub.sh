#!/bin/bash
# Check if coverage/lcov.info exists and print basic stats
if [ -f coverage/lcov.info ]; then
  TOTAL_LINES=$(grep -c "^DA:" coverage/lcov.info)
  COVERED_LINES=$(grep "^DA:" coverage/lcov.info | grep -v ",0$" | wc -l)
  COVERAGE=$(echo "scale=2; $COVERED_LINES / $TOTAL_LINES * 100" | bc)
  echo "Lines: $TOTAL_LINES, Covered: $COVERED_LINES, Coverage: $COVERAGE%"
else
  echo "No coverage found"
fi
