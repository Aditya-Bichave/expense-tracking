import os
import glob
import re

files = glob.glob("lib/features/*/data/repositories/*.dart")
for path in files:
    with open(path, 'r') as f:
        content = f.read()

    # replace log.severe("Exception in repository", e, s); with log.severe("Exception in repository: $e\n$s");
    new_content = re.sub(r'log\.severe\("Exception in repository", e, s\);', r'log.severe("Exception in repository: $e\\n$s");', content)

    with open(path, 'w') as f:
        f.write(new_content)

print("Fixed logger calls")
