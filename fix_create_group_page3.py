import re

f = 'lib/features/groups/presentation/pages/create_group_page.dart'
with open(f, 'r') as file:
    content = file.read()

content = content.replace("  @override\n  \n  Future<void> _pickImage()", "  Future<void> _pickImage()")
with open(f, 'w') as file:
    file.write(content)
