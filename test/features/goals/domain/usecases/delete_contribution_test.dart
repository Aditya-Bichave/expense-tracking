import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/delete_contribution.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalContributionRepository extends Mock implements GoalContributionRepository {}

void main() {
  late DeleteContributionUseCase useCase;
  late MockGoalContributionRepository mockRepository;

  setUp(() {
    mockRepository = MockGoalContributionRepository();
    useCase = DeleteContributionUseCase(mockRepository);
  });

  const tId = '1';

  test('should call deleteContribution on repository', () async {
    // arrange
    when(() => mockRepository.deleteContribution(tId))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await useCase(const DeleteContributionParams(id: tId));

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteContribution(tId));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(() => mockRepository.deleteContribution(tId))
        .thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(const DeleteContributionParams(id: tId));

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.deleteContribution(tId));
  });
}
