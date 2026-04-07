import sys
import os

def parse_lcov(filepath):
    files = {}
    if not os.path.exists(filepath):
        print(f"{filepath} not found")
        return None

    with open(filepath, 'r') as f:
        current_file = None
        lines_found = 0
        lines_hit = 0

        for line in f:
            line = line.strip()
            if line.startswith('SF:'):
                current_file = line[3:]
                files[current_file] = {'found': 0, 'hit': 0}
            elif line.startswith('LF:'):
                files[current_file]['found'] = int(line[3:])
            elif line.startswith('LH:'):
                files[current_file]['hit'] = int(line[3:])
            elif line.startswith('end_of_record'):
                current_file = None

    total_found = sum(f['found'] for f in files.values())
    total_hit = sum(f['hit'] for f in files.values())

    print(f"Total Lines: {total_found}")
    print(f"Covered Lines: {total_hit}")
    print(f"Uncovered Lines: {total_found - total_hit}")
    if total_found > 0:
        print(f"Coverage: {total_hit / total_found * 100:.2f}%")

    file_list = []
    for filepath, data in files.items():
        if data['found'] > 0:
            file_list.append({
                'file': filepath,
                'found': data['found'],
                'hit': data['hit'],
                'missed': data['found'] - data['hit'],
                'coverage': data['hit'] / data['found'] * 100
            })

    file_list.sort(key=lambda x: x['missed'], reverse=True)

    print("\nTop 50 files by uncovered lines:")
    for f in file_list[:50]:
        print(f"{f['missed']:4d} missed | {f['found']:4d} total | {f['coverage']:6.2f}% | {f['file']}")

if __name__ == "__main__":
    parse_lcov("coverage/lcov.info")
