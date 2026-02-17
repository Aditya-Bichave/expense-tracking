import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_goals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late GetGoalsUseCase useCase;
  late MockGoalRepository mockRepository;

  setUp(() {
    mockRepository = MockGoalRepository();
    useCase = GetGoalsUseCase(mockRepository);
  });

  final tGoals = [
    Goal(
      id: '1',
      name: 'Vacation',
      targetAmount: 1000.0,
      status: GoalStatus.active,
      totalSaved: 0.0,
      createdAt: DateTime.now(),
    ),
  ];

  test('should get goals from repository', () async {
    // arrange
    when(
      () => mockRepository.getGoals(),
    ).thenAnswer((_) async => Right(tGoals));

    // act
    final result = await useCase(NoParams());

    // assert
    expect(result, Right(tGoals));
    verify(() => mockRepository.getGoals());
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(
      () => mockRepository.getGoals(),
    ).thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(NoParams());

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.getGoals());
  });
}
