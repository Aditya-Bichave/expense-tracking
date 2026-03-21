import os
import re

files = [
    "lib/features/auth/data/repositories/auth_repository_impl.dart",
    "lib/features/categories/data/repositories/category_repository_impl.dart",
    "lib/features/categories/data/repositories/merchant_category_repository_impl.dart",
    "lib/features/categories/data/repositories/user_history_repository_impl.dart",
    "lib/features/expenses/data/repositories/expense_repository_impl.dart",
    "lib/features/group_expenses/data/repositories/group_expenses_repository_impl.dart",
    "lib/features/groups/data/repositories/groups_repository_impl.dart",
    "lib/features/income/data/repositories/income_repository_impl.dart",
    "lib/features/profile/data/repositories/profile_repository_impl.dart",
    "lib/features/recurring_transactions/data/repositories/recurring_transaction_repository_impl.dart"
]

for file in files:
    if not os.path.exists(file): continue
    with open(file, 'r') as f:
        content = f.read()

    # ensure logger is imported
    if "import 'package:expense_tracker/core/utils/logger.dart';" not in content and "final _log" not in content and "log.severe" not in content:
        # Just add logger if we add log.severe
        pass

    import_logger = "import 'package:expense_tracker/core/utils/logger.dart';"
    has_logger = import_logger in content or "Logger(" in content or "log." in content

    if not has_logger and "catch (e) {" in content:
        content = import_logger + "\n" + content

    new_content = re.sub(r'catch \(e\) \{', r'catch (e, s) {\n      log.severe("Exception in repository", e, s);', content)
    new_content = re.sub(r'catch \(e\) {', r'catch (e, s) {\n      log.severe("Exception in repository", e, s);', new_content)

    with open(file, 'w') as f:
        f.write(new_content)
