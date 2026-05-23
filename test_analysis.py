import os
import glob

def get_lib_files():
    lib_files = []
    for root, _, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart') and not file.endswith('.g.dart') and not file.endswith('.freezed.dart'):
                # Ignore abstract/interfaces, etc if we want, but let's just grab all for now to check test existence
                lib_files.append(os.path.join(root, file))
    return lib_files

def get_test_files():
    test_files = []
    for root, _, files in os.walk('test'):
        for file in files:
            if file.endswith('_test.dart'):
                test_files.append(os.path.join(root, file))
    return test_files

lib_files = get_lib_files()
test_files = get_test_files()

# map test file to likely lib file target
# A typical pattern is test/foo/bar_test.dart targets lib/foo/bar.dart
test_targets = set()
for t in test_files:
    # strip test/ prefix and _test.dart suffix, then add .dart and lib/
    # wait, sometimes test files are nested in `test/features/` while lib is in `lib/features/`
    rel = os.path.relpath(t, 'test')
    base = rel.replace('_test.dart', '.dart')
    target = os.path.join('lib', base)
    test_targets.add(target)

untested = []
for l in lib_files:
    if l not in test_targets:
        # filter out some obvious non-testable ones
        if 'router.dart' in l or 'main.dart' in l or 'constants' in l or 'models' in l:
            continue
        untested.append(l)

print(f"Total lib files: {len(lib_files)}")
print(f"Total test files: {len(test_files)}")
print(f"Untested lib files (approx): {len(untested)}")

# Let's list some untested business logic files
print("\nUntested potential business logic files:")
for u in untested:
    if 'bloc' in u or 'cubit' in u or 'repository' in u or 'usecase' in u or 'service' in u:
        print(u)
