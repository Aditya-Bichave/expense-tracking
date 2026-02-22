import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/add_edit_recurring_rule/add_edit_recurring_rule_bloc.dart';

void main() {
  test('AddEditRecurringRuleState supports equality', () {
    expect(
      AddEditRecurringRuleState(startDate: DateTime(2023)),
      equals(AddEditRecurringRuleState(startDate: DateTime(2023))),
    );
  });
}
