#!/bin/bash
set -e

BASE_REF=${1:-main}
echo "Checking codegen consistency (comparing against $BASE_REF)..."

# Ensure we have base ref fetched
git fetch origin $BASE_REF --depth=1 || true

CHANGED_FILES=$(git diff --name-only "origin/$BASE_REF" -- "lib/*.dart")

VIOLATIONS=0

for file in $CHANGED_FILES; do
  if [ ! -f "$file" ]; then continue; fi

  # Check for annotations that trigger codegen
  if grep -E "@JsonSerializable|@hiveType|@Freezed|@GenerateMocks" "$file" > /dev/null; then
    GEN_FILE="${file%.dart}.g.dart"
    FREEZED_FILE="${file%.dart}.freezed.dart"

    # Check if generated file is in changed files list
    if grep -E "part '$GEN_FILE'" "$file" > /dev/null; then
       if ! echo "$CHANGED_FILES" | grep -F "$GEN_FILE" > /dev/null; then
         echo "❌ Error: $file changed (has codegen annotations) but $GEN_FILE did not change."
         VIOLATIONS=1
       fi
    fi

    if grep -E "part '$FREEZED_FILE'" "$file" > /dev/null; then
       if ! echo "$CHANGED_FILES" | grep -F "$FREEZED_FILE" > /dev/null; then
         echo "⍌ Error: $file changed (has Freezed) but $FREEYED_FILE did not change."
         VIOLATIONS=1
       fi
    fi
  fi
done

if [ $VIOLATIONS -eq 1 ]; then
  echo "Codegen check failed. Please run 'flutter pub run build_runner build' and commit the changes."
  exit 1
else
  echo "⌅ Codegen check passed."
  exit 0
fi
