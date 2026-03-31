import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:expense_tracker/features/categories/domain/entities/user_history_rule.dart';

void main() {
  group('UserHistoryRuleModel Test', () {
    final tTimestamp = DateTime(2023, 1, 1);

    final tModel = UserHistoryRuleModel(
      ruleId: 'r1',
      ruleType: 'merchant',
      matcher: 'Walmart',
      assignedCategoryId: 'c1',
      timestamp: tTimestamp,
    );

    final tEntity = UserHistoryRule(
      id: 'r1',
      ruleType: RuleType.merchant,
      matcher: 'Walmart',
      assignedCategoryId: 'c1',
      timestamp: tTimestamp,
    );

    test('should return a valid model from entity', () {
      final result = UserHistoryRuleModel.fromEntity(tEntity);

      expect(result.ruleId, tModel.ruleId);
      expect(result.ruleType, tModel.ruleType);
      expect(result.matcher, tModel.matcher);
      expect(result.assignedCategoryId, tModel.assignedCategoryId);
      expect(result.timestamp, tModel.timestamp);
    });

    test('should return a valid entity from model', () {
      final result = tModel.toEntity();

      expect(result.id, tEntity.id);
      expect(result.ruleType, tEntity.ruleType);
      expect(result.matcher, tEntity.matcher);
      expect(result.assignedCategoryId, tEntity.assignedCategoryId);
      expect(result.timestamp, tEntity.timestamp);
    });

    test('should return default description ruleType if not merchant', () {
      final modelWithDesc = UserHistoryRuleModel(
        ruleId: 'r2',
        ruleType: 'description',
        matcher: 'Target',
        assignedCategoryId: 'c2',
        timestamp: tTimestamp,
      );

      final entity = modelWithDesc.toEntity();
      expect(entity.ruleType, RuleType.description);

      final modelWithUnknown = UserHistoryRuleModel(
        ruleId: 'r3',
        ruleType: 'unknown',
        matcher: 'Target',
        assignedCategoryId: 'c2',
        timestamp: tTimestamp,
      );

      final entityUnknown = modelWithUnknown.toEntity();
      expect(entityUnknown.ruleType, RuleType.description);
    });
  });
}
