import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_contributions_for_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalContributionRepository extends Mock
    implements GoalContributionRepository {}

void main() {
  late GetContributionsForGoalUseCase usecase;
  late MockGoalContributionRepository mockGoalContributionRepository;

  setUp(() {
    mockGoalContributionRepository = MockGoalContributionRepository();
    usecase = GetContributionsForGoalUseCase(mockGoalContributionRepository);
  });

  final tContributionList = [
    GoalContribution(
      id: 'test_id',
      goalId: 'goal_id',
      amount: 100,
      date: DateTime(2023, 1, 1),
      createdAt: DateTime(2023, 1, 1),
    ),
  ];

  test(
    'should return list of GoalContribution from the repository when successful',
    () async {
      // arrange
      when(
        () => mockGoalContributionRepository.getContributionsForGoal(any()),
      ).thenAnswer((_) async => Right(tContributionList));

      // act
      final result = await usecase(
        const GetContributionsParams(goalId: 'goal_id'),
      );

      // assert
      expect(result, Right(tContributionList));
      verify(
        () => mockGoalContributionRepository.getContributionsForGoal('goal_id'),
      );
      verifyNoMoreInteractions(mockGoalContributionRepository);
    },
  );

  test('should return Failure from the repository when unsuccessful', () async {
    // arrange
    final tFailure = CacheFailure('Cache Error');
    when(
      () => mockGoalContributionRepository.getContributionsForGoal(any()),
    ).thenAnswer((_) async => Left(tFailure));

    // act
    final result = await usecase(
      const GetContributionsParams(goalId: 'goal_id'),
    );

    // assert
    expect(result, Left(tFailure));
    verify(
      () => mockGoalContributionRepository.getContributionsForGoal('goal_id'),
    );
    verifyNoMoreInteractions(mockGoalContributionRepository);
  });
}
