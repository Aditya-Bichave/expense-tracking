import re

f = 'pubspec.yaml'
with open(f, 'r') as file:
    content = file.read()
# Add to dependencies instead of dev_dependencies this time
content = content.replace("  csv: ^6.0.0", "  csv: ^6.0.0\n  pdf: ^3.11.1")
with open(f, 'w') as file:
    file.write(content)
