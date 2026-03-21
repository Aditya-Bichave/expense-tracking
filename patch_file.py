import re

filepath = 'test/features/auth/data/repositories/auth_repository_impl_test.dart'
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace("expect(l.message, 'Exception: error');", "expect(l.message, 'Authentication failed');")

with open(filepath, 'w') as f:
    f.write(content)
