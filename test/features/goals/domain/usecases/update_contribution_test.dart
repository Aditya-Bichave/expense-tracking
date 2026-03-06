import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_contribution.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalContributionRepository extends Mock
    implements GoalContributionRepository {}

class FakeGoalContribution extends Fake implements GoalContribution {}

void main() {
  late UpdateContributionUseCase usecase;
  late MockGoalContributionRepository mockGoalContributionRepository;

  setUpAll(() {
    registerFallbackValue(FakeGoalContribution());
  });

  setUp(() {
    mockGoalContributionRepository = MockGoalContributionRepository();
    usecase = UpdateContributionUseCase(mockGoalContributionRepository);
  });

  final tContribution = GoalContribution(
    id: 'test_id',
    goalId: 'goal_id',
    amount: 100,
    date: DateTime(2023, 1, 1),
    createdAt: DateTime(2023, 1, 1),
  );

  final tInvalidContribution = GoalContribution(
    id: 'test_id',
    goalId: 'goal_id',
    amount: -50,
    date: DateTime(2023, 1, 1),
    createdAt: DateTime(2023, 1, 1),
  );

  test(
    'should return GoalContribution from the repository when successful',
    () async {
      // arrange
      when(
        () => mockGoalContributionRepository.updateContribution(any()),
      ).thenAnswer((_) async => Right(tContribution));

      // act
      final result = await usecase(
        UpdateContributionParams(contribution: tContribution),
      );

      // assert
      expect(result, Right(tContribution));
      verify(
        () => mockGoalContributionRepository.updateContribution(tContribution),
      );
      verifyNoMoreInteractions(mockGoalContributionRepository);
    },
  );

  test(
    'should return ValidationFailure when amount is less than or equal to 0',
    () async {
      // act
      final result = await usecase(
        UpdateContributionParams(contribution: tInvalidContribution),
      );

      // assert
      expect(
        result,
        const Left(ValidationFailure("Contribution amount must be positive.")),
      );
      verifyZeroInteractions(mockGoalContributionRepository);
    },
  );

  test('should return Failure from the repository when unsuccessful', () async {
    // arrange
    final tFailure = CacheFailure('Cache Error');
    when(
      () => mockGoalContributionRepository.updateContribution(any()),
    ).thenAnswer((_) async => Left(tFailure));

    // act
    final result = await usecase(
      UpdateContributionParams(contribution: tContribution),
    );

    // assert
    expect(result, Left(tFailure));
    verify(
      () => mockGoalContributionRepository.updateContribution(tContribution),
    );
    verifyNoMoreInteractions(mockGoalContributionRepository);
  });
}
