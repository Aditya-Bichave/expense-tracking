import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class FakeGoal extends Fake implements Goal {}

void main() {
  late UpdateGoalUseCase useCase;
  late MockGoalRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeGoal());
  });

  setUp(() {
    mockRepository = MockGoalRepository();
    useCase = UpdateGoalUseCase(mockRepository);
  });

  final tGoal = Goal(
    id: '1',
    name: 'Vacation',
    targetAmount: 1000.0,
    status: GoalStatus.active,
    totalSaved: 0.0,
    createdAt: DateTime.now(),
  );

  test('should call updateGoal on repository', () async {
    // arrange
    when(() => mockRepository.updateGoal(tGoal))
        .thenAnswer((_) async => Right(tGoal));

    // act
    final result = await useCase(UpdateGoalParams(goal: tGoal));

    // assert
    expect(result, Right(tGoal)); // Expect the goal back
    verify(() => mockRepository.updateGoal(tGoal));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(() => mockRepository.updateGoal(tGoal))
        .thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(UpdateGoalParams(goal: tGoal));

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.updateGoal(tGoal));
  });
}
