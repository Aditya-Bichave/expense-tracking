import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source_proxy.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_helpers.dart';

void main() {
  late DemoAwareGoalDataSource dataSource;
  late MockHiveGoalLocalDataSource mockHiveDataSource;
  late MockDemoModeService mockDemoModeService;

  setUp(() {
    mockHiveDataSource = MockHiveGoalLocalDataSource();
    mockDemoModeService = MockDemoModeService();
    dataSource = DemoAwareGoalDataSource(
      hiveDataSource: mockHiveDataSource,
      demoModeService: mockDemoModeService,
    );
  });

  final tGoal = GoalModel(
    id: '1',
    name: 'Test Goal',
    targetAmount: 1000.0,
    statusIndex: 0,
    totalSavedCache: 0.0,
    targetDate: DateTime.now().add(const Duration(days: 30)),
    iconName: 'default',
    createdAt: DateTime.now(),
  );

  group('getGoals', () {
    test('should call Hive data source when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.getGoals(),
      ).thenAnswer((_) async => [tGoal]);

      final result = await dataSource.getGoals();

      expect(result, [tGoal]);
      verify(() => mockHiveDataSource.getGoals());
    });

    test('should call Demo service when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(
        () => mockDemoModeService.getDemoGoals(),
      ).thenAnswer((_) async => [tGoal]);

      final result = await dataSource.getGoals();

      expect(result, [tGoal]);
      verify(() => mockDemoModeService.getDemoGoals());
    });
  });

  group('saveGoal', () {
    test('should call Hive data source when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(() => mockHiveDataSource.saveGoal(tGoal)).thenAnswer((_) async {});

      await dataSource.saveGoal(tGoal);

      verify(() => mockHiveDataSource.saveGoal(tGoal));
    });

    test('should call Demo service when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(
        () => mockDemoModeService.saveDemoGoal(tGoal),
      ).thenAnswer((_) async {});

      await dataSource.saveGoal(tGoal);

      verify(() => mockDemoModeService.saveDemoGoal(tGoal));
    });
  });

  group('deleteGoal', () {
    test('should call Hive data source when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(() => mockHiveDataSource.deleteGoal('1')).thenAnswer((_) async {});

      await dataSource.deleteGoal('1');

      verify(() => mockHiveDataSource.deleteGoal('1'));
    });

    test('should call Demo service when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(
        () => mockDemoModeService.deleteDemoGoal('1'),
      ).thenAnswer((_) async {});

      await dataSource.deleteGoal('1');

      verify(() => mockDemoModeService.deleteDemoGoal('1'));
    });
  });

  group('clearAllGoals', () {
    test('should call Hive data source when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(() => mockHiveDataSource.clearAllGoals()).thenAnswer((_) async {});

      await dataSource.clearAllGoals();

      verify(() => mockHiveDataSource.clearAllGoals());
    });

    test('should do nothing when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);

      await dataSource.clearAllGoals();

      verifyNever(() => mockHiveDataSource.clearAllGoals());
    });
  });
}
