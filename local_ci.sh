#!/bin/bash
set -e

echo "Running pub get..."
flutter pub get

echo "Running dart format..."
dart format . --set-exit-if-changed

echo "Running flutter analyze..."
flutter analyze

echo "Running flutter test..."
flutter test
