import os
import glob
import subprocess

def get_files_with_size():
    files_info = []
    for root, _, files in os.walk('lib/features'):
        for file in files:
            if file.endswith('.dart') and not file.endswith('.g.dart') and not file.endswith('.freezed.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r') as f:
                    lines = f.readlines()

                    # count logical lines
                    count = 0
                    for line in lines:
                        line = line.strip()
                        if line and not line.startswith('//') and not line.startswith('import ') and not line.startswith('part '):
                            count += 1

                    if 'test' not in filepath and 'model' not in filepath and 'entity' not in filepath and 'constants' not in filepath:
                        files_info.append((filepath, count))

    # sort by size
    files_info.sort(key=lambda x: x[1], reverse=True)
    return files_info

sizes = get_files_with_size()

print("Checking test coverage for largest files...")
targets = [f[0] for f in sizes[:20]]

for t in targets:
    # check if test file exists
    rel = os.path.relpath(t, 'lib')
    base = rel.replace('.dart', '_test.dart')
    test_path = os.path.join('test', base)

    if os.path.exists(test_path):
        # find test file lines
        with open(test_path, 'r') as f:
            tlines = f.readlines()
            tcount = len(tlines)
        print(f"HAS TEST ({tcount} lines): {t} ({dict(sizes)[t]} lines)")
    else:
        # check alternative paths
        name = os.path.basename(t).replace('.dart', '')
        found = False
        for root, _, files in os.walk('test'):
            for file in files:
                if name in file:
                    test_file = os.path.join(root, file)
                    with open(test_file, 'r') as f:
                        tcount = len(f.readlines())
                    print(f"HAS ALT TEST ({tcount} lines): {t} ({dict(sizes)[t]} lines) -> {test_file}")
                    found = True
                    break
            if found: break

        if not found:
            print(f"NO TEST: {t} ({dict(sizes)[t]} lines)")
