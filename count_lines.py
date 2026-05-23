import os
import re

total_lines = 0
file_count = 0

def is_executable_line(line):
    line = line.strip()
    if not line: return False
    if line.startswith('//'): return False
    if line.startswith('/*') or line.startswith('*') or line.startswith('*/'): return False
    if line == '{' or line == '}' or line == '};' or line == '()': return False
    # skip imports/exports/part/part of
    if line.startswith('import ') or line.startswith('export ') or line.startswith('part '): return False
    # skip simple annotations
    if line.startswith('@'): return False
    # this is naive, but okay for an estimate
    return True

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart') and not file.endswith('.g.dart') and not file.endswith('.freezed.dart'):
            filepath = os.path.join(root, file)
            file_count += 1
            with open(filepath, 'r') as f:
                lines = f.readlines()
                for line in lines:
                    if is_executable_line(line):
                        total_lines += 1

print(f"Total files: {file_count}")
print(f"Total estimated executable lines: {total_lines}")
