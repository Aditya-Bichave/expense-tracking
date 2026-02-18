import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/usecases/delete_custom_category.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

void main() {
  late DeleteCustomCategoryUseCase useCase;
  late MockCategoryRepository mockCategoryRepository;
  late MockExpenseRepository mockExpenseRepository;
  late MockIncomeRepository mockIncomeRepository;

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    mockExpenseRepository = MockExpenseRepository();
    mockIncomeRepository = MockIncomeRepository();
    useCase = DeleteCustomCategoryUseCase(
      mockCategoryRepository,
      mockExpenseRepository,
      mockIncomeRepository,
    );
  });

  const tParams = DeleteCustomCategoryParams(
    categoryId: 'cat1',
    fallbackCategoryId: 'default',
  );

  test('should delete category and reassign transactions', () async {
    // Arrange
    when(
      () => mockExpenseRepository.reassignExpensesCategory(any(), any()),
    ).thenAnswer((_) async => const Right(5));
    when(
      () => mockIncomeRepository.reassignIncomesCategory(any(), any()),
    ).thenAnswer((_) async => const Right(2));
    when(
      () => mockCategoryRepository.deleteCustomCategory(any(), any()),
    ).thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result, const Right(null));
    verify(
      () => mockExpenseRepository.reassignExpensesCategory('cat1', 'default'),
    ).called(1);
    verify(
      () => mockIncomeRepository.reassignIncomesCategory('cat1', 'default'),
    ).called(1);
    verify(
      () => mockCategoryRepository.deleteCustomCategory('cat1', 'default'),
    ).called(1);
  });

  test('should rollback if income reassignment fails', () async {
    // Arrange
    when(
      () => mockExpenseRepository.reassignExpensesCategory(any(), any()),
    ).thenAnswer((_) async => const Right(5));
    when(
      () => mockIncomeRepository.reassignIncomesCategory(any(), any()),
    ).thenAnswer((_) async => const Left(CacheFailure("Fail")));
    when(
      () => mockExpenseRepository.reassignExpensesCategory(
        any(),
        any(),
      ), // Rollback call
    ).thenAnswer((_) async => const Right(5));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result, const Left(CacheFailure("Fail")));
    // Verify rollback called with swapped IDs
    verify(
      () => mockExpenseRepository.reassignExpensesCategory('default', 'cat1'),
    ).called(1);
    verifyNever(
      () => mockCategoryRepository.deleteCustomCategory(any(), any()),
    );
  });
}
