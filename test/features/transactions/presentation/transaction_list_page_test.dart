import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/transaction_list_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getDominantTransactionType', () {
    test('returns null when selected IDs contain a stale entry', () {
      final expense = Expense(
        id: '1',
        title: 'Lunch',
        amount: 10.0,
        date: DateTime(2024, 1, 1),
        category: Category.uncategorized,
        accountId: 'acc1',
      );

      final state = TransactionListState(
        transactions: [TransactionEntity.fromExpense(expense)],
        selectedTransactionIds: const {'1', 'stale-id'},
      );

      final result = getDominantTransactionTypeForTesting(state);

      expect(result, isNull);
    });
  });
}
