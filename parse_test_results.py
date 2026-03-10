import re

with open('test_output.log', 'r') as f:
    log = f.read()

failed_tests = re.findall(r'(\d+:\d+ \+\d+ -\d+: .*(?:\[E\]|Some tests failed|Failed to load).*)', log)
if not failed_tests:
    failed_tests = re.findall(r'(?i)fail.*', log)

print(failed_tests)
