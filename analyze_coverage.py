import os

def analyze_lcov(filepath):
    total_lines = 0
    covered_lines = 0

    with open('coverage_exclusion.txt', 'r') as f:
        exclusions = [line.strip().replace('**/*', '') for line in f if line.strip()]

    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return

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
                total_lines += file_lines
                covered_lines += file_covered
                file_lines = 0
                file_covered = 0

    if total_lines == 0:
        print("No valid lines found.")
    else:
        coverage = (covered_lines / total_lines) * 100
        print(f"Total Lines: {total_lines}")
        print(f"Covered Lines: {covered_lines}")
        print(f"Coverage: {coverage:.2f}%")

analyze_lcov('coverage/lcov.info')
