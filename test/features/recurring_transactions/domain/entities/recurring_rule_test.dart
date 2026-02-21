import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tRule = RecurringRule(
    id: '1',
    userId: 'u1',
    amount: 100.0,
    description: 'Rent',
    categoryId: 'c1',
    accountId: 'a1',
    transactionType: TransactionType.expense,
    frequency: Frequency.monthly,
    interval: 1,
    startDate: tDate,
    dayOfMonth: 1,
    endConditionType: EndConditionType.never,
    status: RuleStatus.active,
    nextOccurrenceDate: tDate,
    occurrencesGenerated: 0,
  );

  group('RecurringRule', () {
    test('props should contain all fields', () {
      expect(tRule.props, [
        '1',
        'u1',
        100.0,
        'Rent',
        'c1',
        'a1',
        TransactionType.expense,
        Frequency.monthly,
        1,
        tDate,
        null, // dayOfWeek
        1, // dayOfMonth
        EndConditionType.never,
        null, // endDate
        null, // totalOccurrences
        RuleStatus.active,
        tDate,
        0,
      ]);
    });

    test('supports value equality', () {
      final tRule2 = RecurringRule(
        id: '1',
        userId: 'u1',
        amount: 100.0,
        description: 'Rent',
        categoryId: 'c1',
        accountId: 'a1',
        transactionType: TransactionType.expense,
        frequency: Frequency.monthly,
        interval: 1,
        startDate: tDate,
        dayOfMonth: 1,
        endConditionType: EndConditionType.never,
        status: RuleStatus.active,
        nextOccurrenceDate: tDate,
        occurrencesGenerated: 0,
      );
      expect(tRule, equals(tRule2));
    });

    test('copyWith should return updated copy', () {
      final updated = tRule.copyWith(
        amount: 150.0,
        description: 'Updated Rent',
      );
      expect(updated.amount, 150.0);
      expect(updated.description, 'Updated Rent');
      expect(updated.id, tRule.id);
    });
  });
}
