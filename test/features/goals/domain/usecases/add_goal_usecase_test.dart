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

class MockUuid extends Mock implements Uuid {}

class MockClock extends Mock implements Clock {}

void main() {
  late AddGoalUseCase useCase;
  late MockGoalRepository mockRepository;
  late MockUuid mockUuid;
  late MockClock mockClock;

  setUp(() {
    mockRepository = MockGoalRepository();
    mockUuid = MockUuid();
    mockClock = MockClock();
    useCase = AddGoalUseCase(mockRepository, mockUuid, mockClock);

    // Default clock behavior
    when(() => mockClock.now()).thenReturn(DateTime(2023, 1, 1));
    registerFallbackValue(
      Goal(
        id: '1',
        name: 'test',
        targetAmount: 100,
        status: GoalStatus.active, // Fixed: Use GoalStatus
        totalSaved: 0,
        createdAt: DateTime.now(),
      ),
    );
  });

  const tGoalParams = AddGoalParams(
    name: 'Vacation',
    targetAmount: 1000,
    iconName: 'savings',
  );

  test('should add goal successfully', () async {
    when(() => mockUuid.v4()).thenReturn('1');
    when(() => mockRepository.addGoal(any())).thenAnswer((invocation) async {
      return Right(invocation.positionalArguments[0] as Goal);
    });

    final result = await useCase(tGoalParams);

    expect(result.isRight(), true);
    verify(() => mockRepository.addGoal(any())).called(1);
  });

  test('should return failure when name is empty', () async {
    final result = await useCase(
      const AddGoalParams(
        name: '',
        targetAmount: 100,
      ),
    );
    expect(result.isLeft(), true);
    result.fold((l) => expect(l, isA<ValidationFailure>()), (r) => null);
  });

  test('should return failure when target amount is negative', () async {
    final result = await useCase(
      const AddGoalParams(
        name: 'Test',
        targetAmount: -100,
      ),
    );
    expect(result.isLeft(), true);
  });
}
