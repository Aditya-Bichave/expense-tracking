import os
import glob

def get_dart_files(directory, exclude_patterns=None):
    if exclude_patterns is None:
        exclude_patterns = []

    dart_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)

                # Check exclusions
                exclude = False
                for pattern in exclude_patterns:
                    if pattern in filepath:
                        exclude = True
                        break

                if not exclude:
                    dart_files.append(filepath)
    return set(dart_files)

lib_files = get_dart_files('lib', ['.g.dart', '.freezed.dart'])
test_files = get_dart_files('test')

# Map lib files to test files based on name
# Usually lib/path/to/file.dart -> test/path/to/file_test.dart
untested_files = []
tested_files = []

for lib_file in lib_files:
    # Handle abstract interfaces by name or content roughly
    filename = os.path.basename(lib_file)
    if filename.endswith('_repository.dart') or filename.endswith('_usecase.dart'):
        continue

    expected_test_name = filename.replace('.dart', '_test.dart')

    # Check if there's any test file with this name
    found_test = False
    for test_file in test_files:
        if os.path.basename(test_file) == expected_test_name:
            found_test = True
            break

    if found_test:
        tested_files.append(lib_file)
    else:
        # Let's count lines
        with open(lib_file, 'r') as f:
            lines = len([l for l in f.readlines() if l.strip() and not l.strip().startswith('//')])
            if lines > 10:  # Skip very small files
                untested_files.append({'file': lib_file, 'lines': lines})

untested_files.sort(key=lambda x: x['lines'], reverse=True)

print(f"Total lib files analyzed: {len(lib_files)}")
print(f"Files with tests: {len(tested_files)}")
print(f"Files without tests (lines > 10): {len(untested_files)}")

print("\nTop untested files by line count:")
for f in untested_files[:30]:
    print(f"{f['lines']:4d} lines | {f['file']}")
