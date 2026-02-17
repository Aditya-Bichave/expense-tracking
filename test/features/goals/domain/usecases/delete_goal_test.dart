import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/delete_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late DeleteGoalUseCase useCase;
  late MockGoalRepository mockRepository;

  setUp(() {
    mockRepository = MockGoalRepository();
    useCase = DeleteGoalUseCase(mockRepository);
  });

  const tGoalId = '1';

  test('should call deleteGoal on repository', () async {
    // arrange
    when(
      () => mockRepository.deleteGoal(tGoalId),
    ).thenAnswer((_) async => const Right(null));

    // act
    final result = await useCase(const DeleteGoalParams(id: tGoalId));

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteGoal(tGoalId));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(
      () => mockRepository.deleteGoal(tGoalId),
    ).thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(const DeleteGoalParams(id: tGoalId));

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.deleteGoal(tGoalId));
  });
}
