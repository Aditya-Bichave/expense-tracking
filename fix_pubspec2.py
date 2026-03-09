f = 'pubspec.yaml'
with open(f, 'r') as file:
    content = file.read()
# Since `pdf: ^3.11.1` might be inside dev_dependencies as well, or `pdf: ^3.11.3`.
import re
content = re.sub(r'  pdf: \^3\.11\.1\n', '', content)
with open(f, 'w') as file:
    file.write(content)
