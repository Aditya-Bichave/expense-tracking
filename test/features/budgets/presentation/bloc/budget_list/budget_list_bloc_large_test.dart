import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';

void main() {
  test('BudgetListState supports equality', () {
    expect(const BudgetListState(), equals(const BudgetListState()));
  });
}
