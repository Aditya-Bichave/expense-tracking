import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/add_edit_budget/add_edit_budget_bloc.dart';

void main() {
  group('AddEditBudgetState', () {
    test('has correct default values', () {
      const state = AddEditBudgetState();
      expect(state.status, AddEditBudgetStatus.initial);
      expect(state.initialBudget, null);
      expect(state.availableCategories, isEmpty);
      expect(state.errorMessage, null);
    });

    test('supports equality with same values', () {
      expect(
        const AddEditBudgetState(status: AddEditBudgetStatus.loading),
        equals(const AddEditBudgetState(status: AddEditBudgetStatus.loading)),
      );
    });

    test('supports inequality with different status', () {
      expect(
        const AddEditBudgetState(status: AddEditBudgetStatus.loading),
        isNot(equals(const AddEditBudgetState(status: AddEditBudgetStatus.success))),
      );
    });

    test('isEditing is false when initialBudget is null', () {
      const state = AddEditBudgetState(initialBudget: null);
      expect(state.isEditing, false);
    });

    test('has all expected status values', () {
      expect(AddEditBudgetStatus.values.length, 4);
      expect(AddEditBudgetStatus.values, contains(AddEditBudgetStatus.initial));
      expect(AddEditBudgetStatus.values, contains(AddEditBudgetStatus.loading));
      expect(AddEditBudgetStatus.values, contains(AddEditBudgetStatus.success));
      expect(AddEditBudgetStatus.values, contains(AddEditBudgetStatus.error));
    });
  });
}