import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_state.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupExpensesState', () {
    test('GroupExpensesInitial supports value comparisons', () {
      expect(const GroupExpensesInitial(), const GroupExpensesInitial());
    });

    test('GroupExpensesLoading supports value comparisons', () {
      expect(const GroupExpensesLoading(), const GroupExpensesLoading());
    });

    test('GroupExpensesLoaded supports value comparisons', () {
      expect(const GroupExpensesLoaded([]), const GroupExpensesLoaded([]));
    });

    test('GroupExpensesError supports value comparisons', () {
      expect(
        const GroupExpensesError('error'),
        const GroupExpensesError('error'),
      );
    });

    test('GroupExpensesOperationFailed supports value comparisons', () {
      expect(
        const GroupExpensesOperationFailed('error', []),
        const GroupExpensesOperationFailed('error', []),
      );
    });

    test('GroupExpenseOperationSucceeded supports value comparisons', () {
      expect(
        const GroupExpenseOperationSucceeded(null),
        const GroupExpenseOperationSucceeded(null),
      );
    });
  });
}
