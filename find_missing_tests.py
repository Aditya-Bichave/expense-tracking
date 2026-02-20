
import os

def main():
    with open('lib_files.txt', 'r') as f:
        lib_files = [line.strip() for line in f.readlines()]

    with open('test_files.txt', 'r') as f:
        test_files = [line.strip() for line in f.readlines()]

    # Normalize paths for comparison
    # lib/path/to/file.dart -> test/path/to/file_test.dart

    missing_tests = []

    for lib_file in lib_files:
        if lib_file.endswith('.freezed.dart') or lib_file.endswith('.g.dart'):
            continue # Skip generated files

        # Construct expected test file path
        rel_path = os.path.relpath(lib_file, 'lib')
        test_path = os.path.join('test', rel_path.replace('.dart', '_test.dart'))

        if test_path not in test_files:
             missing_tests.append(lib_file)

    print("Files without tests:")
    for file in missing_tests:
        print(file)

if __name__ == "__main__":
    main()
