import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/add_edit_recurring_rule/add_edit_recurring_rule_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddEditRecurringRuleEvent', () {
    test('InitializeForEdit supports value comparisons', () {
      final rule = RecurringRule(
        id: '1',
        description: 'test',
        amount: 10,
        transactionType: TransactionType.expense,
        categoryId: '1',
        accountId: '1',
        frequency: Frequency.monthly,
        interval: 1,
        startDate: DateTime(2023),
        nextOccurrenceDate: DateTime(2023),
        occurrencesGenerated: 0,
        status: RuleStatus.active,
        endConditionType: EndConditionType.never,
      );
      expect(InitializeForEdit(rule), InitializeForEdit(rule));
    });

    test('DescriptionChanged supports value comparisons', () {
      expect(
        const DescriptionChanged('test'),
        const DescriptionChanged('test'),
      );
    });

    test('AmountChanged supports value comparisons', () {
      expect(const AmountChanged('10'), const AmountChanged('10'));
    });

    test('TransactionTypeChanged supports value comparisons', () {
      expect(
        const TransactionTypeChanged(TransactionType.expense),
        const TransactionTypeChanged(TransactionType.expense),
      );
    });

    test('AccountChanged supports value comparisons', () {
      expect(const AccountChanged('1'), const AccountChanged('1'));
    });

    test('CategoryChanged supports value comparisons', () {
      final category = Category(
        id: '1',
        name: 'Test',
        type: CategoryType.expense,
        iconName: 'icon',
        colorHex: 'color',
        isCustom: false,
      );
      expect(CategoryChanged(category), CategoryChanged(category));
    });

    test('FrequencyChanged supports value comparisons', () {
      expect(
        const FrequencyChanged(Frequency.daily),
        const FrequencyChanged(Frequency.daily),
      );
    });

    test('IntervalChanged supports value comparisons', () {
      expect(const IntervalChanged('2'), const IntervalChanged('2'));
    });

    test('StartDateChanged supports value comparisons', () {
      final date = DateTime(2023);
      expect(StartDateChanged(date), StartDateChanged(date));
    });

    test('EndConditionTypeChanged supports value comparisons', () {
      expect(
        const EndConditionTypeChanged(EndConditionType.never),
        const EndConditionTypeChanged(EndConditionType.never),
      );
    });

    test('EndDateChanged supports value comparisons', () {
      final date = DateTime(2023);
      expect(EndDateChanged(date), EndDateChanged(date));
    });

    test('TotalOccurrencesChanged supports value comparisons', () {
      expect(
        const TotalOccurrencesChanged('10'),
        const TotalOccurrencesChanged('10'),
      );
    });

    test('DayOfWeekChanged supports value comparisons', () {
      expect(const DayOfWeekChanged(1), const DayOfWeekChanged(1));
    });

    test('DayOfMonthChanged supports value comparisons', () {
      expect(const DayOfMonthChanged(1), const DayOfMonthChanged(1));
    });

    test('TimeChanged supports value comparisons', () {
      const time = TimeOfDay(hour: 1, minute: 1);
      expect(const TimeChanged(time), const TimeChanged(time));
    });

    test('FormSubmitted supports value comparisons', () {
      expect(
        const FormSubmitted(description: 'test', amount: '10'),
        const FormSubmitted(description: 'test', amount: '10'),
      );
    });
  });
}
