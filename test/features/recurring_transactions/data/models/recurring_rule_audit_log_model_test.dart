import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_audit_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tModel = RecurringRuleAuditLogModel(
    id: '1',
    ruleId: 'r1',
    timestamp: tDate,
    userId: 'u1',
    fieldChanged: 'amount',
    oldValue: '100',
    newValue: '200',
  );

  final tEntity = RecurringRuleAuditLog(
    id: '1',
    ruleId: 'r1',
    timestamp: tDate,
    userId: 'u1',
    fieldChanged: 'amount',
    oldValue: '100',
    newValue: '200',
  );

  group('RecurringRuleAuditLogModel', () {
    test('fromEntity should return valid model', () {
      final result = RecurringRuleAuditLogModel.fromEntity(tEntity);
      expect(result.id, tModel.id);
      expect(result.ruleId, tModel.ruleId);
      expect(result.timestamp, tModel.timestamp);
      expect(result.userId, tModel.userId);
      expect(result.fieldChanged, tModel.fieldChanged);
      expect(result.oldValue, tModel.oldValue);
      expect(result.newValue, tModel.newValue);
    });

    test('toEntity should return valid entity', () {
      final result = tModel.toEntity();
      expect(result, equals(tEntity));
    });
  });
}
