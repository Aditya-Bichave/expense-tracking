import os

def process_file(filepath):
    try:
        with open(filepath, 'r') as f:
            lines = f.readlines()

        content = ''.join(lines)

        # Check usage
        if 'log.' not in content and 'log(' not in content:
            return

        # Check existing import
        if "package:expense_tracker/core/utils/logger.dart" in content:
            return

        # Find where to insert
        last_import_idx = -1
        for i, line in enumerate(lines):
            if line.strip().startswith('import '):
                last_import_idx = i

        import_statement = "import 'package:expense_tracker/core/utils/logger.dart';\n"

        if last_import_idx != -1:
            lines.insert(last_import_idx + 1, import_statement)
        else:
            # Insert at top (after library/part of if exists, simpler to just put at top)
            lines.insert(0, import_statement)

        with open(filepath, 'w') as f:
            f.writelines(lines)
        print(f"Updated {filepath}")
    except Exception as e:
        print(f"Skipping {filepath}: {e}")

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
