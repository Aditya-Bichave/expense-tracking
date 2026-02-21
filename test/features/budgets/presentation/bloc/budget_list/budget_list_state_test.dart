import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';

void main() {
  group('BudgetListState', () {
    test('has correct default values', () {
      const state = BudgetListState();
      expect(state.status, BudgetListStatus.loading);
      expect(state.budgetsWithStatus, isEmpty);
      expect(state.errorMessage, null);
    });

    test('supports equality with same values', () {
      expect(
        const BudgetListState(status: BudgetListStatus.loading),
        equals(const BudgetListState(status: BudgetListStatus.loading)),
      );
    });

    test('supports inequality with different status', () {
      expect(
        const BudgetListState(status: BudgetListStatus.loading),
        isNot(equals(const BudgetListState(status: BudgetListStatus.success))),
      );
    });

    test('has all expected status values', () {
      expect(BudgetListStatus.values.length, 3);
      expect(BudgetListStatus.values, contains(BudgetListStatus.loading));
      expect(BudgetListStatus.values, contains(BudgetListStatus.success));
      expect(BudgetListStatus.values, contains(BudgetListStatus.error));
    });
  });
}