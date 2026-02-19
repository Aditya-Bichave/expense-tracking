import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/repositories/goal_contribution_repository_impl.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalContributionLocalDataSource extends Mock
    implements GoalContributionLocalDataSource {}

class MockGoalLocalDataSource extends Mock implements GoalLocalDataSource {}

void main() {
  late GoalContributionRepositoryImpl repository;
  late MockGoalContributionLocalDataSource mockContributionDataSource;
  late MockGoalLocalDataSource mockGoalDataSource;

  setUpAll(() {
    registerFallbackValue(
      GoalContributionModel(
        id: '',
        goalId: '',
        amount: 0,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    registerFallbackValue(
      GoalModel(
        id: '',
        name: '',
        targetAmount: 0,
        statusIndex: 0,
        createdAt: DateTime.now(),
        totalSavedCache: 0,
      ),
    );
  });

  setUp(() {
    mockContributionDataSource = MockGoalContributionLocalDataSource();
    mockGoalDataSource = MockGoalLocalDataSource();
    repository = GoalContributionRepositoryImpl(
      contributionDataSource: mockContributionDataSource,
      goalDataSource: mockGoalDataSource,
    );
  });

  final tDate = DateTime(2023, 1, 1);
  final tGoalId = 'goal1';
  final tContribution = GoalContribution(
    id: '1',
    goalId: tGoalId,
    amount: 50,
    date: tDate,
    note: 'Saving',
    createdAt: tDate,
  );
  final tContributionModel = GoalContributionModel.fromEntity(tContribution);

  final tGoalModel = GoalModel(
    id: tGoalId,
    name: 'Goal',
    targetAmount: 100,
    statusIndex: GoalStatus.active.index,
    createdAt: tDate,
    totalSavedCache: 0,
  );

  test('should add contribution and update goal cache', () async {
    // Arrange
    when(
      () => mockContributionDataSource.saveContribution(any()),
    ).thenAnswer((_) async => Future.value());
    when(
      () => mockContributionDataSource.getContributionsForGoal(tGoalId),
    ).thenAnswer((_) async => [tContributionModel]);
    when(
      () => mockGoalDataSource.getGoalById(tGoalId),
    ).thenAnswer((_) async => tGoalModel);
    when(
      () => mockGoalDataSource.saveGoal(any()),
    ).thenAnswer((_) async => Future.value());

    // Act
    final result = await repository.addContribution(tContribution);

    // Assert
    expect(result, Right(tContribution));

    // Verify saveContribution called with correct data
    final capturedContribution = verify(
      () => mockContributionDataSource.saveContribution(captureAny()),
    ).captured.single as GoalContributionModel;
    expect(capturedContribution.id, tContribution.id);
    expect(capturedContribution.amount, tContribution.amount);

    // Verify cache update
    final capturedGoal =
        verify(() => mockGoalDataSource.saveGoal(captureAny())).captured.single
            as GoalModel;
    expect(capturedGoal.totalSavedCache, 50.0);
  });
}
