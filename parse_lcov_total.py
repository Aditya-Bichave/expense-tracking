import sys
import os

def parse_lcov(filepath):
    lf = 0
    lh = 0
    try:
        with open(filepath, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith('LF:'):
                    lf += int(line[3:])
                elif line.startswith('LH:'):
                    lh += int(line[3:])
        return lf, lh
    except Exception as e:
        print(f"Error reading file {filepath}: {e}")
        return None, None

def analyze_coverage(coverage_file):
    if not os.path.exists(coverage_file):
        print(f"Coverage file {coverage_file} does not exist.")
        return

    lf, lh = parse_lcov(coverage_file)
    if lf:
        pct = (lh / lf) * 100
        print(f"Total Line Coverage: {pct:.2f}% ({lh}/{lf})")
    else:
        print("Failed to calculate coverage.")

if __name__ == '__main__':
    analyze_coverage('coverage/lcov.info')
