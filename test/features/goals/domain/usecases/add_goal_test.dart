import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/services/clock.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class MockClock extends Mock implements Clock {}

class FakeGoal extends Fake implements Goal {}

void main() {
  late AddGoalUseCase useCase;
  late MockGoalRepository mockRepository;
  late MockClock mockClock;
  final uuid = Uuid();

  setUpAll(() {
    registerFallbackValue(FakeGoal());
  });

  setUp(() {
    mockRepository = MockGoalRepository();
    mockClock = MockClock();
    when(() => mockClock.now()).thenReturn(DateTime(2023, 1, 1));
    useCase = AddGoalUseCase(mockRepository, uuid, mockClock);
  });

  final tGoal = Goal(
    id: '1',
    name: 'Vacation',
    targetAmount: 1000.0,
    status: GoalStatus.active,
    totalSaved: 0.0,
    createdAt: DateTime.now(),
  );

  test('should call addGoal on repository', () async {
    // arrange
    when(
      () => mockRepository.addGoal(any()),
    ).thenAnswer((_) async => Right(tGoal));

    // act
    final result = await useCase(
      AddGoalParams(name: tGoal.name, targetAmount: tGoal.targetAmount),
    );

    // assert
    expect(result.isRight(), true);
    verify(() => mockRepository.addGoal(any())).called(1);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(
      () => mockRepository.addGoal(any()),
    ).thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(
      AddGoalParams(name: tGoal.name, targetAmount: tGoal.targetAmount),
    );

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.addGoal(any()));
  });
}
