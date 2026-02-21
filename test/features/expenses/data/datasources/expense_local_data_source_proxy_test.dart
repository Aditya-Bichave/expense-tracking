import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source_proxy.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';

class MockHiveExpenseLocalDataSource extends Mock
    implements HiveExpenseLocalDataSource {}

class MockDemoModeService extends Mock implements DemoModeService {}

void main() {
  late DemoAwareExpenseDataSource dataSource;
  late MockHiveExpenseLocalDataSource mockHiveDataSource;
  late MockDemoModeService mockDemoModeService;

  final tExpense = ExpenseModel(
    id: '1',
    title: 'Test',
    amount: 100,
    date: DateTime(2023),
    categoryId: 'c1',
    accountId: 'a1',
    isRecurring: false,
  );

  setUpAll(() {
    registerFallbackValue(tExpense);
  });

  setUp(() {
    mockHiveDataSource = MockHiveExpenseLocalDataSource();
    mockDemoModeService = MockDemoModeService();
    dataSource = DemoAwareExpenseDataSource(
      hiveDataSource: mockHiveDataSource,
      demoModeService: mockDemoModeService,
    );
  });

  group('addExpense', () {
    test('should forward to Hive when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.addExpense(any()),
      ).thenAnswer((_) async => tExpense);

      await dataSource.addExpense(tExpense);

      verify(() => mockHiveDataSource.addExpense(tExpense));
      verifyNever(() => mockDemoModeService.addDemoExpense(any()));
    });

    test('should forward to DemoService when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(
        () => mockDemoModeService.addDemoExpense(any()),
      ).thenAnswer((_) async => tExpense);

      await dataSource.addExpense(tExpense);

      verify(() => mockDemoModeService.addDemoExpense(tExpense));
      verifyNever(() => mockHiveDataSource.addExpense(any()));
    });

    test('should return the expense from Hive when demo is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.addExpense(any()),
      ).thenAnswer((_) async => tExpense);

      final result = await dataSource.addExpense(tExpense);

      expect(result, tExpense);
    });

    test('should return the expense from DemoService when demo is active',
        () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(
        () => mockDemoModeService.addDemoExpense(any()),
      ).thenAnswer((_) async => tExpense);

      final result = await dataSource.addExpense(tExpense);

      expect(result, tExpense);
    });

    test('should check isDemoActive before each operation', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.addExpense(any()),
      ).thenAnswer((_) async => tExpense);

      await dataSource.addExpense(tExpense);

      verify(() => mockDemoModeService.isDemoActive);
    });
  });
}