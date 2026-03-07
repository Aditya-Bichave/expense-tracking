import re
import subprocess

def get_diff_lines():
    diff = subprocess.check_output(['git', 'diff', 'origin/main', '--unified=0']).decode('utf-8')
    changed_lines = {}
    current_file = None
    for line in diff.split('\n'):
        if line.startswith('+++ b/'):
            current_file = line[6:]
            changed_lines[current_file] = []
        elif line.startswith('@@'):
            # @@ -163,6 +163,13 @@
            m = re.search(r'\+([0-9]+)(?:,([0-9]+))?', line)
            if m and current_file:
                start = int(m.group(1))
                count = int(m.group(2)) if m.group(2) else 1
                for i in range(start, start + count):
                    changed_lines[current_file].append(i)
    return changed_lines

def analyze_lcov_diff(lcov_path, diff_lines):
    covered = 0
    total = 0
    current_file = None

    with open(lcov_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('SF:'):
                current_file = line[3:]
            elif line.startswith('DA:') and current_file in diff_lines:
                parts = line[3:].split(',')
                line_num = int(parts[0])
                hits = int(parts[1])

                if line_num in diff_lines[current_file]:
                    total += 1
                    if hits > 0:
                        covered += 1
                    else:
                        print(f"Missed: {current_file}:{line_num}")

    if total > 0:
        print(f"Diff Coverage: {covered}/{total} ({covered/total*100:.2f}%)")
    else:
        print("No changed lines found in coverage report.")

diffs = get_diff_lines()
analyze_lcov_diff('coverage/lcov.info', diffs)
