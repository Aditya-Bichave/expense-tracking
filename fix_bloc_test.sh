sed -i "s|expect: () => \[|expect: () => \[GroupExpenseOperationSucceeded(tExpense), |g" test/features/group_expenses/presentation/bloc/group_expenses_bloc_test.dart
sed -i "s|expect: () => \[GroupExpenseOperationSucceeded(tExpense), |expect: () => \[|g" test/features/group_expenses/presentation/bloc/group_expenses_bloc_test.dart
