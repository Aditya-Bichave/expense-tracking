import re

files = [
    "lib/features/recurring_transactions/data/repositories/recurring_transaction_repository_impl.dart",
]

for file in files:
    with open(file, 'r') as f:
        content = f.read()

    # Revert the catch block that was added
    content = re.sub(r'catch \(e, s\) \{\n\s*Logger\(".*?"\)\.severe\(".*?", e, s\);\n\s*return', r'catch (e) {\n      return', content)

    with open(file, 'w') as f:
        f.write(content)
