import re
with open("lib/features/recurring_transactions/data/repositories/recurring_transaction_repository_impl.dart", "r") as f:
    content = f.read()

# Revert specific catch blocks that have Logger...
content = re.sub(r'catch \(e, s\) \{\n\s*Logger\("RecurringTransactionRepositoryImpl"\)\.severe\("Exception in repository", e, s\);\n\s*return Left\(CacheFailure\(e\.toString\(\)\)\);\n\s*\}', r'catch (e) {\n      return Left(CacheFailure(e.toString()));\n    }', content)

with open("lib/features/recurring_transactions/data/repositories/recurring_transaction_repository_impl.dart", "w") as f:
    f.write(content)
