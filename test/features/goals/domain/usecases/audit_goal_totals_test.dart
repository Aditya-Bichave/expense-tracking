import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/audit_goal_totals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalContributionRepository extends Mock
    implements GoalContributionRepository {}

void main() {
  late AuditGoalTotalsUseCase usecase;
  late MockGoalContributionRepository mockGoalContributionRepository;

  setUp(() {
    mockGoalContributionRepository = MockGoalContributionRepository();
    usecase = AuditGoalTotalsUseCase(mockGoalContributionRepository);
  });

  test(
    'should call auditGoalTotals from the repository when successful',
    () async {
      // arrange
      when(
        () => mockGoalContributionRepository.auditGoalTotals(),
      ).thenAnswer((_) async => const Right(null));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, const Right(null));
      verify(() => mockGoalContributionRepository.auditGoalTotals());
      verifyNoMoreInteractions(mockGoalContributionRepository);
    },
  );

  test('should return Failure from the repository when unsuccessful', () async {
    // arrange
    final tFailure = CacheFailure('Cache Error');
    when(
      () => mockGoalContributionRepository.auditGoalTotals(),
    ).thenAnswer((_) async => Left(tFailure));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, Left(tFailure));
    verify(() => mockGoalContributionRepository.auditGoalTotals());
    verifyNoMoreInteractions(mockGoalContributionRepository);
  });
}
