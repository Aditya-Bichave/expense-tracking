import re

with open('lib/router.dart', 'r') as f:
    content = f.read()

target = '''    redirect: (context, state) {
      if (const bool.fromEnvironment('E2E_MODE') == true && location == '/e2e-bypass') {'''
replacement = '''    redirect: (context, state) {
      final location = state.uri.path;
      if (const bool.fromEnvironment('E2E_MODE') == true && location == '/e2e-bypass') {'''

content = content.replace(target, replacement)

with open('lib/router.dart', 'w') as f:
    f.write(content)
