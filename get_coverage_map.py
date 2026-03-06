import os

def get_coverage_map(filepath):
    try:
        with open('coverage_exclusion.txt', 'r') as f:
            exclusions = [line.strip().replace('**/*', '') for line in f if line.strip()]
    except FileNotFoundError:
        exclusions = []

    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return

    file_stats = []

    current_file = ""
    file_lines = 0
    file_covered = 0
    valid_file = False

    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('SF:'):
                current_file = line[3:]
                valid_file = True
                for excl in exclusions:
                    if excl in current_file:
                        valid_file = False
                        break
            elif valid_file and line.startswith('DA:'):
                parts = line[3:].split(',')
                if len(parts) >= 2:
                    file_lines += 1
                    if int(parts[1]) > 0:
                        file_covered += 1
            elif valid_file and line == 'end_of_record':
                if file_lines > 0:
                    missed = file_lines - file_covered
                    file_stats.append({
                        'file': current_file,
                        'total': file_lines,
                        'covered': file_covered,
                        'missed': missed,
                        'coverage': (file_covered / file_lines) * 100
                    })
                file_lines = 0
                file_covered = 0

    file_stats.sort(key=lambda x: x['missed'], reverse=True)

    print(f"Total files: {len(file_stats)}")
    target_count = max(20, int(len(file_stats) * 0.2))
    print(f"Target count: {target_count}")

    print("Top files to target for coverage gain:")
    for i, stat in enumerate(file_stats[:target_count]):
        print(f"{i+1}. {stat['file']} - Missed: {stat['missed']}/{stat['total']} ({stat['coverage']:.1f}%)")

get_coverage_map('coverage/lcov.info')
