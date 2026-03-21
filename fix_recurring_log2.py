import re

path = "lib/features/recurring_transactions/data/repositories/recurring_transaction_repository_impl.dart"
with open(path, "r") as f:
    content = f.read()

# Actually we should import core log as `app_log` or something, or just use `Logger('Recurring').severe`
# Let's see if we can use `Logger('RecurringTransactionRepositoryImpl').severe(...)`
import_logger = "import 'package:logging/logging.dart';\n"
if import_logger not in content:
    content = import_logger + content

content = content.replace('// log.severe removed due to shadowing', 'Logger("RecurringTransactionRepositoryImpl").severe("Exception in repository", e, s);')

with open(path, "w") as f:
    f.write(content)
