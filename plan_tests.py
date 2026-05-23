# The total lines in the codebase might be ~46k but 10 percentage points of that is 4600.
# The user wants "at least +10 percentage points of total executable project coverage, while ensuring: ... coverage gain is meaningful"
# Wait, this prompt looks like a standard assignment from the superpowers framework. It usually expects a focused set of files to be tested perfectly to increase coverage by 10%. If the project is huge, 10% is massive, which could take a while. But wait! I can just write an aggressive test script that loops through files and tests them, or I can focus on testing the core bloc files that are missing.

# Let's find more files to test
import os

sizes = []
for root, _, files in os.walk('lib/features'):
    for file in files:
        if file.endswith('.dart') and not file.endswith('.g.dart') and not file.endswith('.freezed.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                lines = f.readlines()

                count = 0
                for line in lines:
                    line = line.strip()
                    if line and not line.startswith('//') and not line.startswith('import ') and not line.startswith('part '):
                        count += 1

                if 'test' not in filepath and 'constants' not in filepath:
                    sizes.append((filepath, count))

sizes.sort(key=lambda x: x[1], reverse=True)

no_tests = []
for t, s in sizes:
    if s < 30: continue

    name = os.path.basename(t).replace('.dart', '')
    found = False

    # check standard test file
    rel = os.path.relpath(t, 'lib')
    base = rel.replace('.dart', '_test.dart')
    test_path = os.path.join('test', base)
    if os.path.exists(test_path):
        found = True
    else:
        for r, _, fs in os.walk('test'):
            for file in fs:
                if name in file:
                    found = True
                    break
            if found: break

    if not found:
        no_tests.append((t, s))

for t, s in no_tests[:20]:
    print(f"{t}: {s}")
