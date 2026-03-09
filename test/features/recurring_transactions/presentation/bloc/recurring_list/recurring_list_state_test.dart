import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/recurring_list/recurring_list_bloc.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurringListState', () {
    test('RecurringListInitial supports value comparisons', () {
      expect(RecurringListInitial(), equals(RecurringListInitial()));
    });

    test('RecurringListLoading supports value comparisons', () {
      expect(RecurringListLoading(), equals(RecurringListLoading()));
    });

    test('RecurringListLoaded supports value comparisons', () {
      final rule1 = RecurringRule(
        id: '1',
        amount: 1000,
        description: 'Rent',
        categoryId: 'cat1',
        accountId: 'acc1',
        transactionType: TransactionType.expense,
        frequency: Frequency.monthly,
        interval: 1,
        startDate: DateTime(2023, 1, 1),
        endConditionType: EndConditionType.never,
        status: RuleStatus.active,
        nextOccurrenceDate: DateTime(2023, 2, 1),
        occurrencesGenerated: 1,
      );
      final rule2 = RecurringRule(
        id: '1',
        amount: 1000,
        description: 'Rent',
        categoryId: 'cat1',
        accountId: 'acc1',
        transactionType: TransactionType.expense,
        frequency: Frequency.monthly,
        interval: 1,
        startDate: DateTime(2023, 1, 1),
        endConditionType: EndConditionType.never,
        status: RuleStatus.active,
        nextOccurrenceDate: DateTime(2023, 2, 1),
        occurrencesGenerated: 1,
      );

      expect(
        RecurringListLoaded([rule1]),
        equals(RecurringListLoaded([rule2])),
      );
      expect(
        const RecurringListLoaded([]),
        isNot(equals(RecurringListLoaded([rule1]))),
      );
    });

    test('RecurringListError supports value comparisons', () {
      expect(
        const RecurringListError('error'),
        equals(const RecurringListError('error')),
      );
      expect(
        const RecurringListError('error'),
        isNot(equals(const RecurringListError('error2'))),
      );
    });
  });
}
