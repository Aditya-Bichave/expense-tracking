// lib/features/categories/data/models/user_history_rule_model.dart
// MODIFIED FILE
import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/features/categories/domain/entities/user_history_rule.dart';

part 'user_history_rule_model.g.dart'; // CORRECTED: Relative path

@HiveType(typeId: 4)
class UserHistoryRuleModel extends HiveObject {
  @HiveField(0)
  final String ruleId;

  @HiveField(1)
  final String ruleType;

  @HiveField(2)
  final String matcher;

  @HiveField(3)
  final String assignedCategoryId;

  @HiveField(4)
  final DateTime timestamp;

  UserHistoryRuleModel({
    required this.ruleId,
    required this.ruleType,
    required this.matcher,
    required this.assignedCategoryId,
    required this.timestamp,
  });

  factory UserHistoryRuleModel.fromEntity(UserHistoryRule entity) {
    return UserHistoryRuleModel(
      ruleId: entity.id,
      ruleType: entity.ruleType.name,
      matcher: entity.matcher,
      assignedCategoryId: entity.assignedCategoryId,
      timestamp: entity.timestamp,
    );
  }

  UserHistoryRule toEntity() {
    RuleType type;
    switch (ruleType) {
      case 'merchant':
        type = RuleType.merchant;
        break;
      case 'description':
      default:
        type = RuleType.description;
        break;
    }
    return UserHistoryRule(
      id: ruleId,
      ruleType: type,
      matcher: matcher,
      assignedCategoryId: assignedCategoryId,
      timestamp: timestamp,
    );
  }
}
