import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_audit_log.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tLog = RecurringRuleAuditLog(
    id: '1',
    ruleId: 'r1',
    timestamp: tDate,
    userId: 'u1',
    fieldChanged: 'amount',
    oldValue: '100',
    newValue: '200',
  );

  group('RecurringRuleAuditLog', () {
    test('props should contain all fields', () {
      expect(tLog.props, [
        '1',
        'r1',
        tDate,
        'u1',
        'amount',
        '100',
        '200',
      ]);
    });

    test('supports value equality', () {
      final tLog2 = RecurringRuleAuditLog(
        id: '1',
        ruleId: 'r1',
        timestamp: tDate,
        userId: 'u1',
        fieldChanged: 'amount',
        oldValue: '100',
        newValue: '200',
      );
      expect(tLog, equals(tLog2));
    });
  });
}
