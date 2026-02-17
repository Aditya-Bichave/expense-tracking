import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/services/clock.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_contribution.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockGoalContributionRepository extends Mock
    implements GoalContributionRepository {}

class MockClock extends Mock implements Clock {}

class FakeGoalContribution extends Fake implements GoalContribution {}

void main() {
  late AddContributionUseCase useCase;
  late MockGoalContributionRepository mockRepository;
  late MockClock mockClock;
  final uuid = Uuid();

  setUpAll(() {
    registerFallbackValue(FakeGoalContribution());
  });

  setUp(() {
    mockRepository = MockGoalContributionRepository();
    mockClock = MockClock();
    when(() => mockClock.now()).thenReturn(DateTime(2023, 1, 1));
    useCase = AddContributionUseCase(mockRepository, uuid, mockClock);
  });

  final tContribution = GoalContribution(
    id: '1',
    goalId: 'g1',
    amount: 100.0,
    date: DateTime.now(),
    createdAt: DateTime.now(),
  );

  test('should call addContribution on repository', () async {
    // arrange
    when(
      () => mockRepository.addContribution(any()),
    ).thenAnswer((_) async => Right(tContribution));

    // act
    final result = await useCase(
      AddContributionParams(
        goalId: tContribution.goalId,
        amount: tContribution.amount,
        date: tContribution.date,
      ),
    );

    // assert
    expect(result.isRight(), true);
    verify(() => mockRepository.addContribution(any())).called(1);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(
      () => mockRepository.addContribution(any()),
    ).thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(
      AddContributionParams(
        goalId: tContribution.goalId,
        amount: tContribution.amount,
        date: tContribution.date,
      ),
    );

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.addContribution(any()));
  });
}
