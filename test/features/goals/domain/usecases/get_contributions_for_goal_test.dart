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
  late GetContributionsForGoalUseCase useCase;
  late MockGoalContributionRepository mockRepository;

  setUp(() {
    mockRepository = MockGoalContributionRepository();
    useCase = GetContributionsForGoalUseCase(mockRepository);
  });

  final tContributions = [
    GoalContribution(
      id: '1',
      goalId: 'g1',
      amount: 100.0,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    ),
  ];
  const tGoalId = 'g1';

  test('should get contributions from repository', () async {
    // arrange
    when(
      () => mockRepository.getContributionsForGoal(tGoalId),
    ).thenAnswer((_) async => Right(tContributions));

    // act
    final result = await useCase(const GetContributionsParams(goalId: tGoalId));

    // assert
    expect(result, Right(tContributions));
    verify(() => mockRepository.getContributionsForGoal(tGoalId));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(
      () => mockRepository.getContributionsForGoal(tGoalId),
    ).thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(const GetContributionsParams(goalId: tGoalId));

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.getContributionsForGoal(tGoalId));
  });
}
