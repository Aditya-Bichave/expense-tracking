f = 'pubspec.yaml'
with open(f, 'r') as file:
    content = file.read()
content = content.replace("  pdf: ^3.11.3", "")
with open(f, 'w') as file:
    file.write(content)
