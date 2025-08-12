import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_audit_log.dart';
import 'package:hive/hive.dart';

part 'recurring_rule_audit_log_model.g.dart';

@HiveType(typeId: 11) // Placeholder TypeId
class RecurringRuleAuditLogModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String ruleId;

  @HiveField(2)
  final DateTime timestamp;

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
    required this.fieldChanged,
    required this.oldValue,
    required this.newValue,
  });

  factory RecurringRuleAuditLogModel.fromEntity(RecurringRuleAuditLog entity) {
    return RecurringRuleAuditLogModel(
      id: entity.id,
      ruleId: entity.ruleId,
      timestamp: entity.timestamp,
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
      fieldChanged: fieldChanged,
      oldValue: oldValue,
      newValue: newValue,
    );
  }
}
