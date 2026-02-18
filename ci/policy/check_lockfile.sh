#!/bin/bash
# Check if pubspec.yaml is modified without pubspec.lock

# Base branch passed as argument, default to main
BASE_REF=${1:-main}

echo "Checking lockfile discipline (comparing against $BASE_REF)..."

# Ensure we have the base ref
git fetch origin $BASE_REF --depth=1 || true

CHANGED_FILES=$(git diff --name-only "origin/$BASE_REF")

HAS_YAML=0
HAS_LOCK=0

if echo "$CHANGED_FILES" | grep -q "pubspec.yaml"; then
  HAS_YAML=1
fi

if echo "$CHANGED_FILES" | grep -q "pubspec.lock"; then
  HAS_LOCK=1
fi

if [ $HAS_YAML -eq 1 ] && [ $HAS_LOCK -eq 0 ]; then
  echo "❌ Error: pubspec.yaml modified but pubspec.lock NOT modified."
  echo "Please run 'flutter pub get' and commit the lockfile."
  exit 1
fi

echo "⌅ Lockfile check passed."
exit 0
