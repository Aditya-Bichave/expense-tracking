#!/bin/bash
flutter pub get
flutter test > flutter_test_output.log 2>&1
grep "Failed" flutter_test_output.log | head -n 20
