import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/check_goal_achievement.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late CheckGoalAchievementUseCase usecase;
  late MockGoalRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      Goal(
        id: '',
        name: '',
        targetAmount: 0,
        totalSaved: 0,
        status: GoalStatus.active,
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockRepository = MockGoalRepository();
    usecase = CheckGoalAchievementUseCase(mockRepository);
  });

  const tGoalId = 'goal1';
  final tGoalActive = Goal(
    id: tGoalId,
    name: 'Test Goal',
    targetAmount: 100,
    totalSaved: 50,
    status: GoalStatus.active,
    createdAt: DateTime.now(),
  );

  final tGoalAchieved = tGoalActive.copyWith(totalSaved: 100);

  test('should return false if goal is not achieved and status is active', () async {
    // Arrange
    when(() => mockRepository.getGoalById(tGoalId))
        .thenAnswer((_) async => Right(tGoalActive));

    // Act
    final result = await usecase(const CheckGoalParams(goalId: tGoalId));

    // Assert
    expect(result, const Right(false));
    verify(() => mockRepository.getGoalById(tGoalId)).called(1);
    verifyNever(() => mockRepository.updateGoal(any()));
  });

  test('should update status and return true if goal is newly achieved', () async {
    // Arrange
    when(() => mockRepository.getGoalById(tGoalId))
        .thenAnswer((_) async => Right(tGoalAchieved));
    when(() => mockRepository.updateGoal(any()))
        .thenAnswer((_) async => Right(tGoalAchieved.copyWith(status: GoalStatus.achieved)));

    // Act
    final result = await usecase(const CheckGoalParams(goalId: tGoalId));

    // Assert
    expect(result, const Right(true));
    verify(() => mockRepository.getGoalById(tGoalId)).called(1);
    final captured = verify(() => mockRepository.updateGoal(captureAny())).captured.single as Goal;
    expect(captured.status, GoalStatus.achieved);
  });

  test('should return false if goal is already achieved', () async {
    // Arrange
    final tGoalAlreadyAchieved = tGoalAchieved.copyWith(status: GoalStatus.achieved);
    when(() => mockRepository.getGoalById(tGoalId))
        .thenAnswer((_) async => Right(tGoalAlreadyAchieved));

    // Act
    final result = await usecase(const CheckGoalParams(goalId: tGoalId));

    // Assert
    expect(result, const Right(false));
    verify(() => mockRepository.getGoalById(tGoalId)).called(1);
    verifyNever(() => mockRepository.updateGoal(any()));
  });

  test('should return failure if goal not found', () async {
    // Arrange
    when(() => mockRepository.getGoalById(tGoalId))
        .thenAnswer((_) async => const Right(null));

    // Act
    final result = await usecase(const CheckGoalParams(goalId: tGoalId));

    // Assert
    expect(result, equals(const Left(CacheFailure("Goal not found."))));
  });
}
