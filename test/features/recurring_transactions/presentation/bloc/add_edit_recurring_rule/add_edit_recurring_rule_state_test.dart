import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/add_edit_recurring_rule/add_edit_recurring_rule_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddEditRecurringRuleState', () {
    test('initial factory returns correctly configured state', () {
      final state = AddEditRecurringRuleState.initial();
      expect(state.startDate, isNotNull);
      expect(state.startTime, isNotNull);
      expect(state.status, FormStatus.initial);
    });

    test('copyWith works correctly', () {
      final state = AddEditRecurringRuleState.initial().copyWith(
        description: 'New Desc',
        amount: 100,
        status: FormStatus.success,
      );

      expect(state.description, 'New Desc');
      expect(state.amount, 100);
      expect(state.status, FormStatus.success);
    });

    test('supports value comparisons', () {
      final date = DateTime(2023);
      expect(
        AddEditRecurringRuleState(startDate: date),
        AddEditRecurringRuleState(startDate: date),
      );
    });
  });
}
