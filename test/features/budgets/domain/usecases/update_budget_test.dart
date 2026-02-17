import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/update_budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late UpdateBudgetUseCase useCase;
  late MockBudgetRepository mockRepository;

  setUp(() {
    mockRepository = MockBudgetRepository();
    useCase = UpdateBudgetUseCase(mockRepository);
  });

  final tBudget = Budget(
    id: '1',
    name: 'Groceries',
    type: BudgetType.categorySpecific,
    targetAmount: 500.0,
    period: BudgetPeriodType.recurringMonthly,
    categoryIds: const ['cat1'], // Required for categorySpecific
    createdAt: DateTime.now(),
  );

  test('should call updateBudget on repository', () async {
    // arrange
    when(() => mockRepository.updateBudget(tBudget)).thenAnswer(
      (_) async => Right(tBudget),
    ); // Assume it returns the updated budget or similar

    // act
    final result = await useCase(UpdateBudgetParams(budget: tBudget));

    // assert
    expect(result.isRight(), true);
    verify(() => mockRepository.updateBudget(tBudget));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(
      () => mockRepository.updateBudget(tBudget),
    ).thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(UpdateBudgetParams(budget: tBudget));

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.updateBudget(tBudget));
  });
}
