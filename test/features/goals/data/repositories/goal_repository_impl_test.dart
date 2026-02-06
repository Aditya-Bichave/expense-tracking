import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalLocalDataSource extends Mock implements GoalLocalDataSource {}

class MockGoalContributionLocalDataSource extends Mock
    implements GoalContributionLocalDataSource {}

void main() {
  late GoalRepositoryImpl repository;
  late MockGoalLocalDataSource mockLocalDataSource;
  late MockGoalContributionLocalDataSource mockContributionDataSource;

  setUpAll(() {
    registerFallbackValue(GoalModel(
      id: '',
      name: '',
      targetAmount: 0,
      statusIndex: GoalStatus.active.index,
      totalSavedCache: 0,
      createdAt: DateTime(2000),
    ));
  });

  setUp(() {
    mockLocalDataSource = MockGoalLocalDataSource();
    mockContributionDataSource = MockGoalContributionLocalDataSource();
    repository = GoalRepositoryImpl(
      localDataSource: mockLocalDataSource,
      contributionDataSource: mockContributionDataSource,
    );
  });

  test('re-evaluates achievement when target amount changes', () async {
    final existingModel = GoalModel(
      id: 'g1',
      name: 'Goal',
      targetAmount: 100,
      targetDate: null,
      iconName: null,
      description: null,
      statusIndex: GoalStatus.achieved.index,
      totalSavedCache: 100,
      createdAt: DateTime(2023, 1, 1),
      achievedAt: DateTime(2023, 2, 1),
    );

    when(
      () => mockLocalDataSource.getGoalById('g1'),
    ).thenAnswer((_) async => existingModel);
    when(() => mockLocalDataSource.saveGoal(any())).thenAnswer((_) async => {});

    final updated = Goal(
      id: 'g1',
      name: 'Goal',
      targetAmount: 200,
      targetDate: null,
      iconName: null,
      description: null,
      status: GoalStatus.achieved,
      totalSaved: 100,
      createdAt: existingModel.createdAt,
      achievedAt: existingModel.achievedAt,
    );

    final result = await repository.updateGoal(updated);

    result.fold((l) => fail('should not fail'), (goal) {
      expect(goal.status, GoalStatus.active);
      expect(goal.achievedAt, isNull);
    });

    final saved = verify(() => mockLocalDataSource.saveGoal(captureAny()))
        .captured
        .single as GoalModel;
    expect(saved.statusIndex, GoalStatus.active.index);
    expect(saved.achievedAt, isNull);
  });

  test('deleteGoal deletes associated contributions using batch delete',
      () async {
    const goalId = 'g1';
    final contributions = <GoalContributionModel>[
      GoalContributionModel(
        id: 'c1',
        goalId: goalId,
        amount: 10,
        date: DateTime(2023),
        note: 'note',
        createdAt: DateTime(2023),
      ),
      GoalContributionModel(
        id: 'c2',
        goalId: goalId,
        amount: 20,
        date: DateTime(2023),
        note: 'note',
        createdAt: DateTime(2023),
      ),
    ];

    when(
      () => mockContributionDataSource.getContributionsForGoal(goalId),
    ).thenAnswer((_) async => contributions);
    when(
      () => mockContributionDataSource.deleteContributions(any()),
    ).thenAnswer((_) async => {});
    when(() => mockLocalDataSource.deleteGoal(goalId))
        .thenAnswer((_) async => {});

    final result = await repository.deleteGoal(goalId);

    expect(result.isRight(), true);
    verify(
      () => mockContributionDataSource.getContributionsForGoal(goalId),
    ).called(1);
    verify(
      () => mockContributionDataSource.deleteContributions(['c1', 'c2']),
    ).called(1);
    verify(() => mockLocalDataSource.deleteGoal(goalId)).called(1);
    verifyNever(() => mockContributionDataSource.deleteContribution(any()));
  });
}
