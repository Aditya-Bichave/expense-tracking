import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source_proxy.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_helpers.dart';

void main() {
  late DemoAwareGoalContributionDataSource dataSource;
  late MockHiveGoalContributionLocalDataSource mockHiveDataSource;
  late MockDemoModeService mockDemoModeService;

  setUp(() {
    mockHiveDataSource = MockHiveGoalContributionLocalDataSource();
    mockDemoModeService = MockDemoModeService();
    dataSource = DemoAwareGoalContributionDataSource(
      hiveDataSource: mockHiveDataSource,
      demoModeService: mockDemoModeService,
    );
  });

  final tContribution = GoalContributionModel(
    id: '1',
    goalId: 'g1',
    amount: 100.0,
    date: DateTime.now(),
    note: 'Test',
    createdAt: DateTime.now(),
  );

  group('getContributionsForGoal', () {
    test('should call Hive data source when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(() => mockHiveDataSource.getContributionsForGoal('g1'))
          .thenAnswer((_) async => [tContribution]);

      final result = await dataSource.getContributionsForGoal('g1');

      expect(result, [tContribution]);
      verify(() => mockHiveDataSource.getContributionsForGoal('g1'));
    });

    test('should call Demo service when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(() => mockDemoModeService.getDemoContributionsForGoal('g1'))
          .thenAnswer((_) async => [tContribution]);

      final result = await dataSource.getContributionsForGoal('g1');

      expect(result, [tContribution]);
      verify(() => mockDemoModeService.getDemoContributionsForGoal('g1'));
    });
  });

  group('saveContribution', () {
    test('should call Hive data source when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(() => mockHiveDataSource.saveContribution(tContribution))
          .thenAnswer((_) async {});

      await dataSource.saveContribution(tContribution);

      verify(() => mockHiveDataSource.saveContribution(tContribution));
    });

    test('should call Demo service when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(() => mockDemoModeService.saveDemoContribution(tContribution))
          .thenAnswer((_) async {});

      await dataSource.saveContribution(tContribution);

      verify(() => mockDemoModeService.saveDemoContribution(tContribution));
    });
  });

  group('deleteContribution', () {
    test('should call Hive data source when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(() => mockHiveDataSource.deleteContribution('1'))
          .thenAnswer((_) async {});

      await dataSource.deleteContribution('1');

      verify(() => mockHiveDataSource.deleteContribution('1'));
    });

    test('should call Demo service when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(() => mockDemoModeService.deleteDemoContribution('1'))
          .thenAnswer((_) async {});

      await dataSource.deleteContribution('1');

      verify(() => mockDemoModeService.deleteDemoContribution('1'));
    });
  });

  group('deleteContributions', () {
    final tIds = ['1', '2'];
    test('should call Hive data source when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(() => mockHiveDataSource.deleteContributions(tIds))
          .thenAnswer((_) async {});

      await dataSource.deleteContributions(tIds);

      verify(() => mockHiveDataSource.deleteContributions(tIds));
    });

    test('should call Demo service when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(() => mockDemoModeService.deleteDemoContributions(tIds))
          .thenAnswer((_) async {});

      await dataSource.deleteContributions(tIds);

      verify(() => mockDemoModeService.deleteDemoContributions(tIds));
    });
  });
}
