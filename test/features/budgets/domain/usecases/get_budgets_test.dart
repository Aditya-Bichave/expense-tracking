import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/get_budgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late GetBudgetsUseCase useCase;
  late MockBudgetRepository mockRepository;

  setUp(() {
    mockRepository = MockBudgetRepository();
    useCase = GetBudgetsUseCase(mockRepository);
  });

  final tBudgets = [
    Budget(
      id: '1',
      name: 'Groceries',
      type: BudgetType.categorySpecific,
      targetAmount: 500.0,
      period: BudgetPeriodType.recurringMonthly,
      createdAt: DateTime.now(),
    )
  ];

  test('should get budgets from repository', () async {
    // arrange
    when(() => mockRepository.getBudgets())
        .thenAnswer((_) async => Right(tBudgets));

    // act
    final result = await useCase(NoParams());

    // assert
    expect(result, Right(tBudgets));
    verify(() => mockRepository.getBudgets());
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(() => mockRepository.getBudgets())
        .thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(NoParams());

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.getBudgets());
  });
}
