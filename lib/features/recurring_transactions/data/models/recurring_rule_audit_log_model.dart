import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_audit_log.dart';
import 'package:hive_ce/hive.dart';

part 'recurring_rule_audit_log_model.g.dart';

@HiveType(typeId: 11) // Placeholder TypeId
class RecurringRuleAuditLogModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String ruleId;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String userId;

  @HiveField(4)
  final String fieldChanged;

  @HiveField(5)
  final String oldValue;

  @HiveField(6)
  final String newValue;

  RecurringRuleAuditLogModel({
    required this.id,
    required this.ruleId,
    required this.timestamp,
    required this.userId,
    required this.fieldChanged,
    required this.oldValue,
    required this.newValue,
  });

  factory RecurringRuleAuditLogModel.fromEntity(RecurringRuleAuditLog entity) {
    return RecurringRuleAuditLogModel(
      id: entity.id,
      ruleId: entity.ruleId,
      timestamp: entity.timestamp,
      userId: entity.userId,
      fieldChanged: entity.fieldChanged,
      oldValue: entity.oldValue,
      newValue: entity.newValue,
    );
  }

  RecurringRuleAuditLog toEntity() {
    return RecurringRuleAuditLog(
      id: id,
      ruleId: ruleId,
      timestamp: timestamp,
      userId: userId,
      fieldChanged: fieldChanged,
      oldValue: oldValue,
      newValue: newValue,
    );
  }
}
