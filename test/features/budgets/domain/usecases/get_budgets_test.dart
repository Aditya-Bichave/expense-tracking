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

  final tBudget = Budget(
    id: '1',
    name: 'Test',
    targetAmount: 100,
    period: BudgetPeriodType.oneTime,
    startDate: DateTime.now(),
    categoryIds: const [],
    type: BudgetType.overall,
    createdAt: DateTime.now(),
  );

  test('should get budgets from repository', () async {
    // Arrange
    when(
      () => mockRepository.getBudgets(),
    ).thenAnswer((_) async => Right([tBudget]));

    // Act
    final result = await useCase(const NoParams());

    // Assert
    expect(result.isRight(), isTrue);
    result.fold(
      (failure) => fail('Should have returned Right'),
      (budgets) {
        expect(budgets.length, 1);
        expect(budgets.first, tBudget);
      },
    );
    verify(() => mockRepository.getBudgets()).called(1);
  });
}
