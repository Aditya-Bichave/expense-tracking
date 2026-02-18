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

  const tId = '1';

  test('should delete goal from repository', () async {
    // Arrange
    when(() => mockRepository.deleteGoal(any()))
        .thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(const DeleteGoalParams(id: tId));

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteGoal(tId)).called(1);
  });
}
