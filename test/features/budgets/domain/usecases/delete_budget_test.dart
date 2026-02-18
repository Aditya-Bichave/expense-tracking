import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/delete_budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late DeleteBudgetUseCase useCase;
  late MockBudgetRepository mockRepository;

  setUp(() {
    mockRepository = MockBudgetRepository();
    useCase = DeleteBudgetUseCase(mockRepository);
  });

  const tId = '1';

  test('should delete budget from repository', () async {
    // Arrange
    when(
      () => mockRepository.deleteBudget(any()),
    ).thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(const DeleteBudgetParams(id: tId));

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteBudget(tId)).called(1);
  });
}
