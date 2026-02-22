import 'package:expense_tracker/features/recurring_transactions/data/datasources/recurring_transaction_local_data_source.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringRuleBox extends Mock implements Box<RecurringRuleModel> {}

class MockAuditLogBox extends Mock implements Box<RecurringRuleAuditLogModel> {}

class FakeRecurringRuleModel extends Fake implements RecurringRuleModel {
  @override
  String get id => '1';
}

class FakeRecurringRuleAuditLogModel extends Fake
    implements RecurringRuleAuditLogModel {
  @override
  String get id => 'log1';
  @override
  String get ruleId => '1';
}

void main() {
  late RecurringTransactionLocalDataSourceImpl dataSource;
  late MockRecurringRuleBox mockRecurringRuleBox;
  late MockAuditLogBox mockAuditLogBox;

  setUpAll(() {
    registerFallbackValue(FakeRecurringRuleModel());
    registerFallbackValue(FakeRecurringRuleAuditLogModel());
  });

  setUp(() {
    mockRecurringRuleBox = MockRecurringRuleBox();
    mockAuditLogBox = MockAuditLogBox();
    dataSource = RecurringTransactionLocalDataSourceImpl(
      recurringRuleBox: mockRecurringRuleBox,
      recurringRuleAuditLogBox: mockAuditLogBox,
    );
  });

  group('RecurringTransactionLocalDataSource', () {
    test('addRecurringRule calls box.put', () async {
      when(() => mockRecurringRuleBox.put(any(), any())).thenAnswer((_) async {
        return;
      });
      await dataSource.addRecurringRule(FakeRecurringRuleModel());
      verify(() => mockRecurringRuleBox.put('1', any())).called(1);
    });

    test('getRecurringRules returns values', () async {
      when(
        () => mockRecurringRuleBox.values,
      ).thenReturn([FakeRecurringRuleModel()]);
      final result = await dataSource.getRecurringRules();
      expect(result.length, 1);
    });

    test('addAuditLog calls box.put', () async {
      when(() => mockAuditLogBox.put(any(), any())).thenAnswer((_) async {
        return;
      });
      await dataSource.addAuditLog(FakeRecurringRuleAuditLogModel());
      verify(() => mockAuditLogBox.put('log1', any())).called(1);
    });

    test('getAuditLogsForRule filters by ruleId', () async {
      when(
        () => mockAuditLogBox.values,
      ).thenReturn([FakeRecurringRuleAuditLogModel()]);
      final result = await dataSource.getAuditLogsForRule('1');
      expect(result.length, 1);
    });
  });
}
