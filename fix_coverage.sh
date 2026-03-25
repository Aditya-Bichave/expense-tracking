#!/bin/bash
# Put back catch (e, s) and we will just remove the "\n$s" from log statements to fix coverage
git checkout HEAD -- lib/features
git checkout HEAD -- lib/core
git checkout HEAD -- lib/main.dart test/core/utils/color_utils_test.dart
