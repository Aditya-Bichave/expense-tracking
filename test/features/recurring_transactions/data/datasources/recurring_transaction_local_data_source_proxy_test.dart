import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/recurring_transactions/data/datasources/recurring_transaction_local_data_source.dart';
import 'package:expense_tracker/features/recurring_transactions/data/datasources/recurring_transaction_local_data_source_proxy.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringTransactionLocalDataSource extends Mock
    implements RecurringTransactionLocalDataSource {}

class MockDemoModeService extends Mock implements DemoModeService {}

class MockRecurringRuleModel extends Mock implements RecurringRuleModel {
  @override
  String get description => 'Mock Rule';
}

class MockRecurringRuleAuditLogModel extends Mock
    implements RecurringRuleAuditLogModel {}

void main() {
  late DemoAwareRecurringTransactionDataSource proxy;
  late MockRecurringTransactionLocalDataSource mockHiveDataSource;
  late MockDemoModeService mockDemoModeService;

  setUp(() {
    mockHiveDataSource = MockRecurringTransactionLocalDataSource();
    mockDemoModeService = MockDemoModeService();
    proxy = DemoAwareRecurringTransactionDataSource(
      hiveDataSource: mockHiveDataSource,
      demoModeService: mockDemoModeService,
    );

    registerFallbackValue(MockRecurringRuleModel());
    registerFallbackValue(MockRecurringRuleAuditLogModel());
  });

  group('addRecurringRule', () {
    test(
      'should delegate to DemoModeService when demo mode is active',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(true);
        when(
          () => mockDemoModeService.addDemoRecurringRule(any()),
        ).thenAnswer((_) async {});
        final rule = MockRecurringRuleModel();

        await proxy.addRecurringRule(rule);

        verify(() => mockDemoModeService.addDemoRecurringRule(rule)).called(1);
        verifyZeroInteractions(mockHiveDataSource);
      },
    );

    test(
      'should delegate to HiveDataSource when demo mode is inactive',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(false);
        when(
          () => mockHiveDataSource.addRecurringRule(any()),
        ).thenAnswer((_) async {});
        final rule = MockRecurringRuleModel();

        await proxy.addRecurringRule(rule);

        verify(() => mockHiveDataSource.addRecurringRule(rule)).called(1);
        verifyNever(() => mockDemoModeService.addDemoRecurringRule(any()));
      },
    );
  });

  group('getRecurringRules', () {
    test(
      'should delegate to DemoModeService when demo mode is active',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(true);
        final rules = [MockRecurringRuleModel()];
        when(
          () => mockDemoModeService.getDemoRecurringRules(),
        ).thenAnswer((_) async => rules);

        final result = await proxy.getRecurringRules();

        expect(result, rules);
        verify(() => mockDemoModeService.getDemoRecurringRules()).called(1);
        verifyZeroInteractions(mockHiveDataSource);
      },
    );

    test(
      'should delegate to HiveDataSource when demo mode is inactive',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(false);
        final rules = [MockRecurringRuleModel()];
        when(
          () => mockHiveDataSource.getRecurringRules(),
        ).thenAnswer((_) async => rules);

        final result = await proxy.getRecurringRules();

        expect(result, rules);
        verify(() => mockHiveDataSource.getRecurringRules()).called(1);
        verifyNever(() => mockDemoModeService.getDemoRecurringRules());
      },
    );
  });

  group('getRecurringRuleById', () {
    test(
      'should delegate to DemoModeService when demo mode is active',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(true);
        final rule = MockRecurringRuleModel();
        when(
          () => mockDemoModeService.getDemoRecurringRuleById(any()),
        ).thenAnswer((_) async => rule);

        final result = await proxy.getRecurringRuleById('id');

        expect(result, rule);
        verify(
          () => mockDemoModeService.getDemoRecurringRuleById('id'),
        ).called(1);
        verifyZeroInteractions(mockHiveDataSource);
      },
    );

    test(
      'should throw Exception when demo mode is active and rule not found',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(true);
        when(
          () => mockDemoModeService.getDemoRecurringRuleById(any()),
        ).thenAnswer((_) async => null);

        expect(() => proxy.getRecurringRuleById('id'), throwsException);
      },
    );

    test(
      'should delegate to HiveDataSource when demo mode is inactive',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(false);
        final rule = MockRecurringRuleModel();
        when(
          () => mockHiveDataSource.getRecurringRuleById(any()),
        ).thenAnswer((_) async => rule);

        final result = await proxy.getRecurringRuleById('id');

        expect(result, rule);
        verify(() => mockHiveDataSource.getRecurringRuleById('id')).called(1);
        verifyNever(() => mockDemoModeService.getDemoRecurringRuleById(any()));
      },
    );
  });

  group('updateRecurringRule', () {
    test(
      'should delegate to DemoModeService when demo mode is active',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(true);
        when(
          () => mockDemoModeService.updateDemoRecurringRule(any()),
        ).thenAnswer((_) async {});
        final rule = MockRecurringRuleModel();

        await proxy.updateRecurringRule(rule);

        verify(
          () => mockDemoModeService.updateDemoRecurringRule(rule),
        ).called(1);
        verifyZeroInteractions(mockHiveDataSource);
      },
    );

    test(
      'should delegate to HiveDataSource when demo mode is inactive',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(false);
        when(
          () => mockHiveDataSource.updateRecurringRule(any()),
        ).thenAnswer((_) async {});
        final rule = MockRecurringRuleModel();

        await proxy.updateRecurringRule(rule);

        verify(() => mockHiveDataSource.updateRecurringRule(rule)).called(1);
        verifyNever(() => mockDemoModeService.updateDemoRecurringRule(any()));
      },
    );
  });

  group('deleteRecurringRule', () {
    test(
      'should delegate to DemoModeService when demo mode is active',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(true);
        when(
          () => mockDemoModeService.deleteDemoRecurringRule(any()),
        ).thenAnswer((_) async {});

        await proxy.deleteRecurringRule('id');

        verify(
          () => mockDemoModeService.deleteDemoRecurringRule('id'),
        ).called(1);
        verifyZeroInteractions(mockHiveDataSource);
      },
    );

    test(
      'should delegate to HiveDataSource when demo mode is inactive',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(false);
        when(
          () => mockHiveDataSource.deleteRecurringRule(any()),
        ).thenAnswer((_) async {});

        await proxy.deleteRecurringRule('id');

        verify(() => mockHiveDataSource.deleteRecurringRule('id')).called(1);
        verifyNever(() => mockDemoModeService.deleteDemoRecurringRule(any()));
      },
    );
  });

  group('addAuditLog', () {
    test(
      'should delegate to DemoModeService when demo mode is active',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(true);
        when(
          () => mockDemoModeService.addDemoRecurringAuditLog(any()),
        ).thenAnswer((_) async {});
        final log = MockRecurringRuleAuditLogModel();

        await proxy.addAuditLog(log);

        verify(
          () => mockDemoModeService.addDemoRecurringAuditLog(log),
        ).called(1);
        verifyZeroInteractions(mockHiveDataSource);
      },
    );

    test(
      'should delegate to HiveDataSource when demo mode is inactive',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(false);
        when(
          () => mockHiveDataSource.addAuditLog(any()),
        ).thenAnswer((_) async {});
        final log = MockRecurringRuleAuditLogModel();

        await proxy.addAuditLog(log);

        verify(() => mockHiveDataSource.addAuditLog(log)).called(1);
        verifyNever(() => mockDemoModeService.addDemoRecurringAuditLog(any()));
      },
    );
  });

  group('getAuditLogsForRule', () {
    test(
      'should delegate to DemoModeService when demo mode is active',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(true);
        final logs = [MockRecurringRuleAuditLogModel()];
        when(
          () => mockDemoModeService.getDemoRecurringAuditLogsForRule(any()),
        ).thenAnswer((_) async => logs);

        final result = await proxy.getAuditLogsForRule('id');

        expect(result, logs);
        verify(
          () => mockDemoModeService.getDemoRecurringAuditLogsForRule('id'),
        ).called(1);
        verifyZeroInteractions(mockHiveDataSource);
      },
    );

    test(
      'should delegate to HiveDataSource when demo mode is inactive',
      () async {
        when(() => mockDemoModeService.isDemoActive).thenReturn(false);
        final logs = [MockRecurringRuleAuditLogModel()];
        when(
          () => mockHiveDataSource.getAuditLogsForRule(any()),
        ).thenAnswer((_) async => logs);

        final result = await proxy.getAuditLogsForRule('id');

        expect(result, logs);
        verify(() => mockHiveDataSource.getAuditLogsForRule('id')).called(1);
        verifyNever(
          () => mockDemoModeService.getDemoRecurringAuditLogsForRule(any()),
        );
      },
    );
  });
}
