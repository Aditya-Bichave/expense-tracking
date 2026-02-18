import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/update_budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

class FakeBudget extends Fake implements Budget {}

void main() {
  late UpdateBudgetUseCase useCase;
  late MockBudgetRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeBudget());
  });

  setUp(() {
    mockRepository = MockBudgetRepository();
    useCase = UpdateBudgetUseCase(mockRepository);
  });

  final tBudget = Budget(
    id: '1',
    name: 'Updated Budget',
    targetAmount: 200.0,
    period: BudgetPeriodType.oneTime,
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 1)),
    categoryIds: const [],
    type: BudgetType.overall,
    createdAt: DateTime.now(),
  );

  test('should update budget in repository', () async {
    // Arrange
    when(
      () => mockRepository.updateBudget(any()),
    ).thenAnswer((_) async => Right(tBudget));

    // Act
    final result = await useCase(UpdateBudgetParams(budget: tBudget));

    // Assert
    expect(result, Right(tBudget));
    verify(() => mockRepository.updateBudget(tBudget)).called(1);
  });
}
