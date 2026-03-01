#!/bin/bash
flutter pub get
flutter analyze
flutter test --coverage --test-randomize-ordering-seed=random --concurrency 16
