#!/bin/bash

# Base branch passed as argument, default to main
BASE_REF=${1:-main}

echo "Checking for policy violations in new code (comparing against $BASE_REF)..."

# Ensure we have the base ref available
git fetch origin $BASE_REF --depth=1 || true

VIOLATIONS=0

# Check for print() or debugPrint() in added lines
echo "Scanning for print() or debugPrint()..."
# Look for lines added (+) that contain print( or debugPrint(
FOUND_PRINT=$(git diff "origin/$BASE_REF" -- "lib/*.dart" | grep -E "^\+.*(print\(|debugPrint\()")

if [ -n "$FOUND_PRINT" ]; then
  echo "❌ Error: Found print() or debugPrint() in changed lines."
  echo "$FOUND_PRINT"
  VIOLATIONS=1
fi

# Check for TODO/FIXME without ticket ID
echo "Scanning for TODO/FIXME without ticket ID..."
# A valid TODO looks like: TODO(TICKET-123) or TODO(#123)
# We exclude lines that match the valid pattern.
FOUND_TODO=$(git diff "origin/$BASE_REF" -- "lib/*.dart" | grep -E "^\.*(TODO|FIXME)" | grep -vE "TODO\([A-Z]+-[0-9]+\)|TODO\(#50-9]+\)")

if [ -n "$FOUND_TODO" ]; then
  echo "❌ Error: Found TODO or FIXME without ticket ID (e.g., TODO(ABC-123))."
  echo "$FOUND_TODO"
  VIOLATIONS=1
fi

if [ $VIOLATIONS -eq 1 ]; then
  echo "Policy check failed."
  exit 1
else
  echo "⌅ Policy check passed."
  exit 0
fi
