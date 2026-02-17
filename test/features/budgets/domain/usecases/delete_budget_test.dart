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

  const tBudgetId = '1';

  test('should call deleteBudget on repository', () async {
    // arrange
    when(
      () => mockRepository.deleteBudget(tBudgetId),
    ).thenAnswer((_) async => const Right(null));

    // act
    final result = await useCase(const DeleteBudgetParams(id: tBudgetId));

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteBudget(tBudgetId));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(
      () => mockRepository.deleteBudget(tBudgetId),
    ).thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(const DeleteBudgetParams(id: tBudgetId));

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.deleteBudget(tBudgetId));
  });
}
