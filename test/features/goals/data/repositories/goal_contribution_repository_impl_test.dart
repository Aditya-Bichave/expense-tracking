import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/repositories/goal_contribution_repository_impl.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalContributionLocalDataSource extends Mock
    implements GoalContributionLocalDataSource {}

class MockGoalLocalDataSource extends Mock implements GoalLocalDataSource {}

void main() {
  late GoalContributionRepositoryImpl repository;
  late MockGoalContributionLocalDataSource mockContributionDataSource;
  late MockGoalLocalDataSource mockGoalDataSource;

  setUp(() {
    mockContributionDataSource = MockGoalContributionLocalDataSource();
    mockGoalDataSource = MockGoalLocalDataSource();
    repository = GoalContributionRepositoryImpl(
      contributionDataSource: mockContributionDataSource,
      goalDataSource: mockGoalDataSource,
    );
    registerFallbackValue(
      GoalContributionModel(
        id: '1',
        goalId: 'g1',
        amount: 50,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    registerFallbackValue(
      GoalModel(
        id: 'g1',
        name: 'G',
        targetAmount: 100,
        statusIndex: 0,
        totalSavedCache: 0,
        createdAt: DateTime.now(),
      ),
    );
  });

  final tContribution = GoalContribution(
    id: '1',
    goalId: 'g1',
    amount: 50,
    date: DateTime.now(),
    createdAt: DateTime.now(),
  );

  final tContributionValid = tContribution.copyWith(
    date: DateTime.now(),
    createdAt: DateTime.now(),
  );

  group('addContribution', () {
    test('should save contribution and update goal cache', () async {
      when(() => mockContributionDataSource.saveContribution(any())).thenAnswer((_) async {});
      when(() => mockContributionDataSource.getContributionsForGoal('g1'))
          .thenAnswer((_) async => [GoalContributionModel.fromEntity(tContributionValid)]);
      when(() => mockGoalDataSource.getGoalById('g1')).thenAnswer(
        (_) async => GoalModel(
          id: 'g1',
          name: 'G',
          targetAmount: 100,
          statusIndex: 0,
          totalSavedCache: 0,
          createdAt: DateTime.now(),
        ),
      );
      when(() => mockGoalDataSource.saveGoal(any())).thenAnswer((_) async {});

      final result = await repository.addContribution(tContributionValid);

      expect(result.isRight(), true);
      verify(() => mockContributionDataSource.saveContribution(any())).called(1);
      verify(() => mockGoalDataSource.saveGoal(any())).called(1);
    });
  });

  group('auditGoalTotals', () {
    test('should fetch all goals and update cache concurrently', () async {
      final goals = [
        GoalModel(id: 'g1', name: 'G1', targetAmount: 100, statusIndex: 0, totalSavedCache: 0, createdAt: DateTime.now()),
        GoalModel(id: 'g2', name: 'G2', targetAmount: 200, statusIndex: 0, totalSavedCache: 0, createdAt: DateTime.now()),
      ];

      when(() => mockGoalDataSource.getGoals()).thenAnswer((_) async => goals);

      when(() => mockContributionDataSource.getContributionsForGoal('g1'))
          .thenAnswer((_) async => [GoalContributionModel(id: 'c1', goalId: 'g1', amount: 50, date: DateTime.now(), createdAt: DateTime.now())]);

      when(() => mockContributionDataSource.getContributionsForGoal('g2'))
          .thenAnswer((_) async => [GoalContributionModel(id: 'c2', goalId: 'g2', amount: 150, date: DateTime.now(), createdAt: DateTime.now())]);

      when(() => mockGoalDataSource.getGoalById(any())).thenAnswer((inv) async {
        final id = inv.positionalArguments[0] as String;
        return goals.firstWhere((g) => g.id == id);
      });

      when(() => mockGoalDataSource.saveGoal(any())).thenAnswer((_) async {});

      final result = await repository.auditGoalTotals();

      expect(result.isRight(), true);
      verify(() => mockGoalDataSource.getGoals()).called(1);
      verify(() => mockContributionDataSource.getContributionsForGoal('g1')).called(1);
      verify(() => mockContributionDataSource.getContributionsForGoal('g2')).called(1);
      verify(() => mockGoalDataSource.saveGoal(any())).called(2);
    });

    test('should log warning when goal cache update fails but continue auditing', () async {
      final goals = [
        GoalModel(id: 'g1', name: 'G1', targetAmount: 100, statusIndex: 0, totalSavedCache: 0, createdAt: DateTime.now()),
      ];

      when(() => mockGoalDataSource.getGoals()).thenAnswer((_) async => goals);

      when(() => mockContributionDataSource.getContributionsForGoal('g1'))
          .thenThrow(Exception('Simulated error'));

      final result = await repository.auditGoalTotals();

      expect(result.isRight(), true);
      verify(() => mockGoalDataSource.getGoals()).called(1);
    });

    test('should return CacheFailure when getting goals throws', () async {
      when(() => mockGoalDataSource.getGoals()).thenThrow(Exception('Failed to get goals'));

      final result = await repository.auditGoalTotals();

      expect(result.isLeft(), true);
    });
  });
}
