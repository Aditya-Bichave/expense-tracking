import sys

def count_lines(filepath):
    try:
        with open(filepath, 'r') as f:
            lines = f.readlines()
            # Simple heuristic for executable lines
            executable = 0
            for line in lines:
                l = line.strip()
                if l and not l.startswith('//') and not l.startswith('import ') and not l.startswith('export ') and l != '{' and l != '}':
                    executable += 1
            return executable
    except Exception as e:
        return 0

total_lines = 0
for filepath in sys.argv[1:]:
    total_lines += count_lines(filepath)

print(total_lines)
