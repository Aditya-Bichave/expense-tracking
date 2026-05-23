import os
import glob
import subprocess

def get_coverage_baseline():
    print("Finding total lines...")
    # This is a bit slow but let's check some files manually for size if we can't run full coverage

def get_files_with_size():
    files_info = []
    for root, _, files in os.walk('lib/features'):
        for file in files:
            if file.endswith('.dart') and not file.endswith('.g.dart') and not file.endswith('.freezed.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r') as f:
                    lines = f.readlines()
                    files_info.append((filepath, len(lines)))

    # sort by size
    files_info.sort(key=lambda x: x[1], reverse=True)
    return files_info

sizes = get_files_with_size()
for f, s in sizes[:20]:
    print(f"{s} lines: {f}")
