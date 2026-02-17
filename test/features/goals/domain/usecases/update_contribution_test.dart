import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_contribution.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalContributionRepository extends Mock implements GoalContributionRepository {}

class FakeGoalContribution extends Fake implements GoalContribution {}

void main() {
  late UpdateContributionUseCase useCase;
  late MockGoalContributionRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeGoalContribution());
  });

  setUp(() {
    mockRepository = MockGoalContributionRepository();
    useCase = UpdateContributionUseCase(mockRepository);
  });

  final tContribution = GoalContribution(
    id: '1',
    goalId: 'g1',
    amount: 100.0,
    date: DateTime.now(),
    createdAt: DateTime.now(),
  );

  test('should call updateContribution on repository', () async {
    // arrange
    when(() => mockRepository.updateContribution(tContribution))
        .thenAnswer((_) async => Right(tContribution));

    // act
    final result = await useCase(UpdateContributionParams(contribution: tContribution));

    // assert
    expect(result, Right(tContribution));
    verify(() => mockRepository.updateContribution(tContribution));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(() => mockRepository.updateContribution(tContribution))
        .thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(UpdateContributionParams(contribution: tContribution));

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.updateContribution(tContribution));
  });
}
