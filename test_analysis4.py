import os
import glob
import subprocess

def check_test_for(target):
    # find test files mapping to target
    rel = os.path.relpath(target, 'lib')
    base = rel.replace('.dart', '_test.dart')
    test_path = os.path.join('test', base)
    if os.path.exists(test_path):
        return test_path

    # Try different mappings for bloc and repositories
    name = os.path.basename(target).replace('.dart', '')

    # Let's search all tests for the file name
    for root, _, files in os.walk('test'):
        for file in files:
            if name in file:
                return os.path.join(root, file)
    return None

targets = [
    "lib/features/reports/data/repositories/report_repository_impl.dart",
    "lib/features/transactions/presentation/bloc/transaction_list_bloc.dart",
    "lib/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart",
    "lib/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart",
    "lib/features/settings/presentation/bloc/settings_bloc.dart",
]

for t in targets:
    print(f"{t}: {check_test_for(t)}")
