import 'package:equatable/equatable.dart';

class RecurringRuleAuditLog extends Equatable {
  final String id;
  final String ruleId;
  final DateTime timestamp;
  final String userId;
  final String fieldChanged; // e.g., 'amount', 'description'
  final String oldValue;
  final String newValue;

  const RecurringRuleAuditLog({
    required this.id,
    required this.ruleId,
    required this.timestamp,
    required this.userId,
    required this.fieldChanged,
    required this.oldValue,
    required this.newValue,
  });

  @override
  List<Object?> get props => [
        id,
        ruleId,
        timestamp,
        userId,
        fieldChanged,
        oldValue,
        newValue,
      ];
}
