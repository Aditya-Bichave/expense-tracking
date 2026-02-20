import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tRule = RecurringRule(
    id: '1',
    userId: 'u1',
    amount: 100,
    description: 'Rent',
    categoryId: 'c1',
    accountId: 'a1',
    transactionType: TransactionType.expense,
    frequency: Frequency.monthly,
    interval: 1,
    startDate: DateTime(2023, 1, 1),
    dayOfMonth: 1,
    endConditionType: EndConditionType.never,
    status: RuleStatus.active,
    nextOccurrenceDate: DateTime(2023, 2, 1),
    occurrencesGenerated: 1,
  );

  final tRuleModel = RecurringRuleModel(
    id: '1',
    userId: 'u1',
    amount: 100,
    description: 'Rent',
    categoryId: 'c1',
    accountId: 'a1',
    transactionTypeIndex: TransactionType.expense.index,
    frequencyIndex: Frequency.monthly.index,
    interval: 1,
    startDate: DateTime(2023, 1, 1),
    dayOfMonth: 1,
    endConditionTypeIndex: EndConditionType.never.index,
    statusIndex: RuleStatus.active.index,
    nextOccurrenceDate: DateTime(2023, 2, 1),
    occurrencesGenerated: 1,
  );

  group('RecurringRuleModel', () {
    test('toEntity should return valid entity', () {
      final result = tRuleModel.toEntity();
      expect(result, tRule);
    });

    test('fromEntity should return valid model', () {
      final result = RecurringRuleModel.fromEntity(tRule);
      expect(result.id, tRuleModel.id);
      expect(result.transactionTypeIndex, tRuleModel.transactionTypeIndex);
    });
  });
}
