import re

path = "lib/features/recurring_transactions/data/repositories/recurring_transaction_repository_impl.dart"
with open(path, "r") as f:
    content = f.read()

# Fix `log.severe` called on `log` variable which is actually `RecurringRuleAuditLog` locally.
content = re.sub(r'log\.severe\("Exception in repository: \$e\\n\$s"\);', r'// log.severe removed due to shadowing', content)

with open(path, "w") as f:
    f.write(content)
