import re

with open('lib/router.dart', 'r') as f:
    content = f.read()

# Insert the bypass exemption at the start of the redirect method
target = '    redirect: (context, state) {\n      final sessionState ='
replacement = '''    redirect: (context, state) {
      final location = state.uri.path;
      if (const bool.fromEnvironment('E2E_MODE') == true && location == '/e2e-bypass') {
        return null; // Exempt bypass page from all auth and profile guards
      }

      final sessionState ='''

content = content.replace(target, replacement)

# We also need to remove the "final location = state.uri.path;" that happens later to avoid redeclaration
content = content.replace('      final location = state.uri.path;\n', '')

with open('lib/router.dart', 'w') as f:
    f.write(content)
