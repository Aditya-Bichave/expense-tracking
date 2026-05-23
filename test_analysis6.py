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

                if 'test' not in filepath and 'model' not in filepath and 'entity' not in filepath and 'constants' not in filepath:
                    sizes.append((filepath, count))

sizes.sort(key=lambda x: x[1], reverse=True)

print("Checking test coverage for all logic files...")

no_tests = []
for t, s in sizes:
    if s < 30: continue

    # check if test file exists
    rel = os.path.relpath(t, 'lib')
    base = rel.replace('.dart', '_test.dart')
    test_path = os.path.join('test', base)

    name = os.path.basename(t).replace('.dart', '')
    found = False
    if os.path.exists(test_path):
        found = True
    else:
        for root, _, files in os.walk('test'):
            for file in files:
                if name in file:
                    found = True
                    break
            if found: break

    if not found:
        no_tests.append((t, s))

for t, s in no_tests[:20]:
    print(f"NO TEST: {t} ({s} lines)")
