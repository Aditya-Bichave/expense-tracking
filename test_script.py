import re

log = ""
with open('test_output.log', 'r') as f:
    log = f.read()

# find other failed tests
matches = re.findall(r'\/app\/test\/([^:]+): [^\n]+\[E\]', log)
print(list(set(matches)))
