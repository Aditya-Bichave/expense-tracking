import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/archive_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late ArchiveGoalUseCase usecase;
  late MockGoalRepository mockGoalRepository;

  setUp(() {
    mockGoalRepository = MockGoalRepository();
    usecase = ArchiveGoalUseCase(mockGoalRepository);
  });

  const tGoalId = 'goal1';
  final tGoal = Goal(
    id: tGoalId,
    name: 'Test Goal',
    targetAmount: 100,
    totalSaved: 0,
    status: GoalStatus.active,
    createdAt: DateTime.now(),
  );

  test('should archive goal using repository', () async {
    // Arrange
    when(
      () => mockGoalRepository.archiveGoal(any()),
    ).thenAnswer((_) async => Right(tGoal));

    // Act
    final result = await usecase(const ArchiveGoalParams(id: tGoalId));

    // Assert
    expect(result, const Right(null));
    verify(() => mockGoalRepository.archiveGoal(tGoalId)).called(1);
    verifyNoMoreInteractions(mockGoalRepository);
  });
}
