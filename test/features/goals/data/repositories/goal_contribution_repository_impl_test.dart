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
    date: DateTime.now(), // Fixed: Non-null
    createdAt: DateTime.now(), // Fixed: Non-null
  );

  final tContributionValid = tContribution.copyWith(
    date: DateTime.now(),
    createdAt: DateTime.now(),
  );

  group('addContribution', () {
    test('should save contribution and update goal cache', () async {
      // 1. Save Contribution success
      when(
        () => mockContributionDataSource.saveContribution(any()),
      ).thenAnswer((_) async {});

      // 2. _updateGoalTotalSavedCache mocks
      // Get contributions
      when(
        () => mockContributionDataSource.getContributionsForGoal('g1'),
      ).thenAnswer(
        (_) async => [GoalContributionModel.fromEntity(tContributionValid)],
      );
      // Get Goal
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
      // Save Goal
      when(() => mockGoalDataSource.saveGoal(any())).thenAnswer((_) async {});

      final result = await repository.addContribution(tContributionValid);

      expect(result.isRight(), true);
      verify(
        () => mockContributionDataSource.saveContribution(any()),
      ).called(1);
      verify(
        () => mockGoalDataSource.saveGoal(any()),
      ).called(1); // Cache update
    });
  });
}
