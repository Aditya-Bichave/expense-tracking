import sys

file_path = 'lib/router.dart'

with open(file_path, 'r') as f:
    lines = f.readlines()

new_lines = []
skip_next = False
ui_kit_route_code = "        path: '/ui-kit',"

# We want to keep the one at the top level (indentation usually 6 spaces or less in routes list)
# But inside branches it might be deeper.
# Let's verify indentation.
# Top level routes: indentation 6 spaces.
# Branch routes: indentation 14 spaces.
# Sub routes: indentation 18+ spaces.

for i in range(len(lines)):
    line = lines[i]
    if ui_kit_route_code in line:
        # Check indentation
        indent = len(line) - len(line.lstrip())
        if indent > 8: # Arbitrary threshold, assuming top level is less indented
            # Skip this line and the builder line following it
            # Actually, GoRoute is usually 3-4 lines.
            # We need to be careful.
            # Easier to just remove the lines if we can identify the block.
            # But parsing line by line is risky.
            pass
        else:
            # Keep top level
            pass

# Better approach: Read the file, identify the incorrect blocks by context.
# The incorrect blocks are inside "routes: [" of other routes.

content = "".join(lines)

# Remove the specific duplicate block
# It looks like:
#                   GoRoute(
#                     path: '/ui-kit',
#                     builder: (context, state) => const UiKitShowcasePage(),
#                   ),

bad_block = """                  GoRoute(
                    path: '/ui-kit',
                    builder: (context, state) => const UiKitShowcasePage(),
                  ),
"""

bad_block_2 = """              GoRoute(
                path: '/ui-kit',
                builder: (context, state) => const UiKitShowcasePage(),
              ),
"""

# Be careful with indentation. Python strings preserve it.
# Let's try to match exactly what  output showed.

# I'll rely on the fact that I want to remove these blocks if they are NOT the first one.
# But string replacement replaces all.

# Let's use regex or just selective removal.
# Or I can just overwrite lib/router.dart with the cleaned content since I have the file content in history.
# That's safer. I'll construct the file content without the bad routes.

pass
