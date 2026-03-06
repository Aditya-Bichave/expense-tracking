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
  late GetGoalsUseCase usecase;
  late MockGoalRepository mockGoalRepository;

  setUp(() {
    mockGoalRepository = MockGoalRepository();
    usecase = GetGoalsUseCase(mockGoalRepository);
  });

  final tGoalList = [
    Goal(
      id: 'test_id',
      name: 'Test Goal',
      targetAmount: 1000,
      totalSaved: 500,
      targetDate: DateTime(2023, 12, 31),
      status: GoalStatus.active,
      createdAt: DateTime(2023, 1, 1),
    ),
  ];

  test(
    'should return list of Goal from the repository when successful',
    () async {
      // arrange
      when(
        () => mockGoalRepository.getGoals(
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer((_) async => Right(tGoalList));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, Right(tGoalList));
      verify(() => mockGoalRepository.getGoals(includeArchived: false));
      verifyNoMoreInteractions(mockGoalRepository);
    },
  );

  test('should return Failure from the repository when unsuccessful', () async {
    // arrange
    final tFailure = CacheFailure('Cache Error');
    when(
      () => mockGoalRepository.getGoals(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => Left(tFailure));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, Left(tFailure));
    verify(() => mockGoalRepository.getGoals(includeArchived: false));
    verifyNoMoreInteractions(mockGoalRepository);
  });
}
