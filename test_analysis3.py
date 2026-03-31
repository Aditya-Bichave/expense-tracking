import os
import glob
import re

lib_dir = "lib"
test_dir = "test"

# Find all dart files in lib excluding .g.dart, .freezed.dart
lib_files = []
for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart") and not file.endswith(".g.dart") and not file.endswith(".freezed.dart"):
            lib_files.append(os.path.join(root, file))

# Find all dart test files
test_files = []
for root, _, files in os.walk(test_dir):
    for file in files:
        if file.endswith("_test.dart"):
            test_files.append(os.path.join(root, file))

untested_files = []
for lib_file in lib_files:
    # Construct expected test file path
    rel_path = os.path.relpath(lib_file, lib_dir)
    test_file_path = os.path.join(test_dir, rel_path.replace(".dart", "_test.dart"))

    if test_file_path not in test_files:
        untested_files.append(lib_file)

# Look for high value untested files (blocs, repositories, usecases)
high_value_untested = []
for f in untested_files:
    # only include abstract files
    if ("bloc" in f or "cubit" in f or "repository" in f or "usecase" in f or "service" in f or "controller" in f or "provider" in f or "notifier" in f or "model" in f or "entity" in f):
        if not f.endswith("_state.dart") and not f.endswith("_event.dart") and "repository.dart" in f:
            high_value_untested.append(f)

print(f"\nHigh value untested interfaces: {len(high_value_untested)}")
for f in high_value_untested:
    print(f)
