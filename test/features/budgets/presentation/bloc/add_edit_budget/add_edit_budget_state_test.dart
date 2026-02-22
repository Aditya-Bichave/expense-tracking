import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/add_edit_budget/add_edit_budget_bloc.dart';

void main() {
  test('AddEditBudgetInitial supports equality', () {
    expect(const AddEditBudgetState().status, AddEditBudgetStatus.initial);
  });
}
