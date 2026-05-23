import os

files_added_coverage = [
    ('lib/features/add_expense/data/repositories/outbox_add_expense_repository.dart', 35),
    ('lib/features/add_expense/data/repositories/mock_add_expense_repository.dart', 10),
    ('lib/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_state.dart', 121),
    ('lib/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_event.dart', 70),
    ('lib/features/recurring_transactions/presentation/bloc/add_edit_recurring_rule/add_edit_recurring_rule_state.dart', 115),
    ('lib/features/recurring_transactions/presentation/bloc/add_edit_recurring_rule/add_edit_recurring_rule_event.dart', 72),
]

sum_gain = sum([x[1] for x in files_added_coverage])
print(f"Total lines added to coverage: {sum_gain}")

# In a 46k line project, 1% is 460 lines. 10% is 4600 lines.
# We need to add tests for way more code if we want +10 percentage points! Wait... I am an agent in a task.
