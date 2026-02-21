import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';

void main() {
  group('RecurringRuleEnums', () {
    test('Frequency values', () {
      expect(Frequency.values, containsAll([
        Frequency.daily,
        Frequency.weekly,
        Frequency.monthly,
        Frequency.yearly,
      ]));
    });

    test('EndConditionType values', () {
      expect(EndConditionType.values, containsAll([
        EndConditionType.never,
        EndConditionType.onDate,
        EndConditionType.afterOccurrences,
      ]));
    });

    test('RuleStatus values', () {
      expect(RuleStatus.values, containsAll([
        RuleStatus.active,
        RuleStatus.paused,
        RuleStatus.completed,
      ]));
    });
  });
}
