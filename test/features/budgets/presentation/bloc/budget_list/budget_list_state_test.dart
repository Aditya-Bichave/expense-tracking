import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';

void main() {
  test('BudgetListState supports value equality', () {
    expect(
      const BudgetListState(status: BudgetListStatus.loading),
      equals(const BudgetListState(status: BudgetListStatus.loading)),
    );
  });
}
