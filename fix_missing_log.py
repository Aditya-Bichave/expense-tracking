import re

path = "lib/features/recurring_transactions/data/repositories/recurring_transaction_repository_impl.dart"
with open(path, "r") as f:
    content = f.read()

import_log = "import 'package:expense_tracker/core/utils/logger.dart';\n"
if "package:expense_tracker/core/utils/logger.dart" not in content:
    content = import_log + content

with open(path, "w") as f:
    f.write(content)
