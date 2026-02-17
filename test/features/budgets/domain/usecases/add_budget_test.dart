import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/add_budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

class FakeBudget extends Fake implements Budget {}

void main() {
  late AddBudgetUseCase useCase;
  late MockBudgetRepository mockRepository;
  final uuid = Uuid();

  setUpAll(() {
    registerFallbackValue(FakeBudget());
  });

  setUp(() {
    mockRepository = MockBudgetRepository();
    useCase = AddBudgetUseCase(mockRepository, uuid);
  });

  final tBudget = Budget(
    id: '1',
    name: 'Groceries',
    type: BudgetType.categorySpecific,
    targetAmount: 500.0,
    period: BudgetPeriodType.recurringMonthly,
    categoryIds: const [
      'cat1',
    ], // Must validate category presence for categorySpecific
    createdAt: DateTime.now(),
  );

  test('should call addBudget on repository', () async {
    // arrange
    when(
      () => mockRepository.addBudget(any()),
    ).thenAnswer((_) async => Right(tBudget));

    // act
    final result = await useCase(
      AddBudgetParams(
        name: tBudget.name,
        targetAmount: tBudget.targetAmount,
        period: tBudget.period,
        type: tBudget.type,
        categoryIds: tBudget.categoryIds,
      ),
    );

    // assert
    expect(result.isRight(), true);
    verify(() => mockRepository.addBudget(any())).called(1);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(
      () => mockRepository.addBudget(any()),
    ).thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(
      AddBudgetParams(
        name: tBudget.name,
        targetAmount: tBudget.targetAmount,
        period: tBudget.period,
        type: tBudget.type,
        categoryIds: tBudget.categoryIds,
      ),
    );

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.addBudget(any()));
  });
}
