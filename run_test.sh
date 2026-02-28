#!/bin/bash
flutter pub get
flutter analyze
flutter test test/features/groups/
