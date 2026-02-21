import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/categories/domain/entities/user_history_rule.dart';

void main() {
  const tId = 'rule1';
  const tRuleType = RuleType.merchant;
  const tMatcher = 'merch123';
  const tCategoryId = 'cat1';
  final tTimestamp = DateTime(2023, 1, 1);

  group('UserHistoryRule', () {
    test('props should contain all fields', () {
      final rule = UserHistoryRule(
        id: tId,
        ruleType: tRuleType,
        matcher: tMatcher,
        assignedCategoryId: tCategoryId,
        timestamp: tTimestamp,
      );
      expect(rule.props, [
        tId,
        tRuleType,
        tMatcher,
        tCategoryId,
        tTimestamp,
      ]);
    });

    test('supports value equality', () {
      final rule1 = UserHistoryRule(
        id: tId,
        ruleType: tRuleType,
        matcher: tMatcher,
        assignedCategoryId: tCategoryId,
        timestamp: tTimestamp,
      );
      final rule2 = UserHistoryRule(
        id: tId,
        ruleType: tRuleType,
        matcher: tMatcher,
        assignedCategoryId: tCategoryId,
        timestamp: tTimestamp,
      );
      expect(rule1, equals(rule2));
    });
  });
}
