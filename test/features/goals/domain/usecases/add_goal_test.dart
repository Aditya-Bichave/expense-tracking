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
  });

  final tGoal = Goal(
    id: '1',
    name: 'Car',
    targetAmount: 5000.0,
    totalSaved: 0.0,
    targetDate: DateTime(2025, 1, 1),
    iconName: 'car',
    description: 'Save for car',
    status: GoalStatus.active,
    createdAt: DateTime(2024, 1, 1),
    achievedAt: null,
  );

  test('should add goal to repository', () async {
    // Arrange
    when(() => mockUuid.v4()).thenReturn('1');
    when(() => mockClock.now()).thenReturn(DateTime(2024, 1, 1));
    when(() => mockRepository.addGoal(any()))
        .thenAnswer((_) async => Right(tGoal));

    // Act
    final result = await useCase(
      AddGoalParams(
        name: tGoal.name,
        targetAmount: tGoal.targetAmount,
        targetDate: tGoal.targetDate,
        iconName: tGoal.iconName,
        description: tGoal.description,
      ),
    );

    // Assert
    expect(result.isRight(), isTrue);
    verify(() => mockRepository.addGoal(any())).called(1);
  });

  test('should return Failure when repository fails', () async {
    // Arrange
    when(() => mockUuid.v4()).thenReturn('1');
    when(() => mockClock.now()).thenReturn(DateTime(2024, 1, 1));
    when(() => mockRepository.addGoal(any()))
        .thenAnswer((_) async => const Left(CacheFailure("Fail")));

    // Act
    final result = await useCase(
      AddGoalParams(
        name: tGoal.name,
        targetAmount: tGoal.targetAmount,
        targetDate: tGoal.targetDate,
        iconName: tGoal.iconName,
        description: tGoal.description,
      ),
    );

    // Assert
    expect(result, const Left(CacheFailure("Fail")));
  });
}
