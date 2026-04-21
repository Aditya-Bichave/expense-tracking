import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source_proxy.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';

class MockHiveBudgetLocalDataSource extends Mock
    implements HiveBudgetLocalDataSource {}

class MockDemoModeService extends Mock implements DemoModeService {}

void main() {
  late DemoAwareBudgetDataSource dataSource;
  late MockHiveBudgetLocalDataSource mockHiveDataSource;
  late MockDemoModeService mockDemoModeService;
  setUpAll(() {
    registerFallbackValue(
      BudgetModel(
        id: "fb",
        name: "fb",
        budgetTypeIndex: 0,
        targetAmount: 0,
        periodTypeIndex: 0,
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockHiveDataSource = MockHiveBudgetLocalDataSource();
    mockDemoModeService = MockDemoModeService();
    dataSource = DemoAwareBudgetDataSource(
      hiveDataSource: mockHiveDataSource,
      demoModeService: mockDemoModeService,
    );
  });

  final tBudgetModel = BudgetModel(
    id: '1',
    name: 'Test Budget',
    budgetTypeIndex: 0,
    targetAmount: 1000.0,
    periodTypeIndex: 0,
    createdAt: DateTime(2023, 1, 1),
  );

  final List<BudgetModel> tBudgetList = [tBudgetModel];

  group('getBudgets', () {
    test('should return demo budgets when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(
        () => mockDemoModeService.getDemoBudgets(),
      ).thenAnswer((_) async => tBudgetList);

      final result = await dataSource.getBudgets();

      expect(result, tBudgetList);
      verify(() => mockDemoModeService.isDemoActive).called(1);
      verify(() => mockDemoModeService.getDemoBudgets()).called(1);
      verifyNever(() => mockHiveDataSource.getBudgets());
    });

    test('should return hive budgets when demo mode is not active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.getBudgets(),
      ).thenAnswer((_) async => tBudgetList);

      final result = await dataSource.getBudgets();

      expect(result, tBudgetList);
      verify(() => mockDemoModeService.isDemoActive).called(1);
      verify(() => mockHiveDataSource.getBudgets()).called(1);
      verifyNever(() => mockDemoModeService.getDemoBudgets());
    });
  });

  group('getBudgetById', () {
    test('should return demo budget when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(
        () => mockDemoModeService.getDemoBudgetById(any()),
      ).thenAnswer((_) async => tBudgetModel);

      final result = await dataSource.getBudgetById('1');

      expect(result, tBudgetModel);
      verify(() => mockDemoModeService.getDemoBudgetById('1')).called(1);
      verifyNever(() => mockHiveDataSource.getBudgetById(any()));
    });

    test('should return hive budget when demo mode is not active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.getBudgetById(any()),
      ).thenAnswer((_) async => tBudgetModel);

      final result = await dataSource.getBudgetById('1');

      expect(result, tBudgetModel);
      verify(() => mockHiveDataSource.getBudgetById('1')).called(1);
      verifyNever(() => mockDemoModeService.getDemoBudgetById(any()));
    });
  });

  group('saveBudget', () {
    test('should save demo budget when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(
        () => mockDemoModeService.saveDemoBudget(any()),
      ).thenAnswer((_) async => Future<void>.value());

      await dataSource.saveBudget(tBudgetModel);

      verify(() => mockDemoModeService.saveDemoBudget(tBudgetModel)).called(1);
      verifyNever(() => mockHiveDataSource.saveBudget(any()));
    });

    test('should save hive budget when demo mode is not active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.saveBudget(any()),
      ).thenAnswer((_) async => Future<void>.value());

      await dataSource.saveBudget(tBudgetModel);

      verify(() => mockHiveDataSource.saveBudget(tBudgetModel)).called(1);
      verifyNever(() => mockDemoModeService.saveDemoBudget(any()));
    });
  });

  group('deleteBudget', () {
    test('should delete demo budget when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(
        () => mockDemoModeService.deleteDemoBudget(any()),
      ).thenAnswer((_) async => Future<void>.value());

      await dataSource.deleteBudget('1');

      verify(() => mockDemoModeService.deleteDemoBudget('1')).called(1);
      verifyNever(() => mockHiveDataSource.deleteBudget(any()));
    });

    test('should delete hive budget when demo mode is not active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.deleteBudget(any()),
      ).thenAnswer((_) async => Future<void>.value());

      await dataSource.deleteBudget('1');

      verify(() => mockHiveDataSource.deleteBudget('1')).called(1);
      verifyNever(() => mockDemoModeService.deleteDemoBudget(any()));
    });
  });

  group('clearAllBudgets', () {
    test('should ignore when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);

      await dataSource.clearAllBudgets();

      verifyNever(() => mockHiveDataSource.clearAllBudgets());
    });

    test('should clear hive budgets when demo mode is not active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.clearAllBudgets(),
      ).thenAnswer((_) async => Future<void>.value());

      await dataSource.clearAllBudgets();

      verify(() => mockHiveDataSource.clearAllBudgets()).called(1);
    });
  });
}
