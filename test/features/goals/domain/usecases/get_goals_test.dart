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

  final tGoal = Goal(
    id: '1',
    name: 'Car',
    targetAmount: 5000.0,
    totalSaved: 1000.0,
    targetDate: DateTime(2025, 1, 1),
    iconName: 'car',
    description: 'Save for car',
    status: GoalStatus.active,
    createdAt: DateTime(2024, 1, 1),
    achievedAt: null,
  );

  test('should get goals from repository', () async {
    // Arrange
    when(
      () => mockRepository.getGoals(),
    ).thenAnswer((_) async => Right([tGoal]));

    // Act
    final result = await useCase(const NoParams());

    // Assert
    expect(result, Right([tGoal]));
    verify(() => mockRepository.getGoals()).called(1);
  });
}
