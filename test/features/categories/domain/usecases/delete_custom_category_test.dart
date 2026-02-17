
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

  const tCategoryId = '1';
  const tFallbackId = '2';
  const tParams = DeleteCustomCategoryParams(
    categoryId: tCategoryId,
    fallbackCategoryId: tFallbackId,
  );

  test('should reassign expenses, incomes and delete category', () async {
    // arrange
    when(() => mockExpenseRepository.reassignExpensesCategory(any(), any()))
        .thenAnswer((_) async => const Right(1));
    when(() => mockIncomeRepository.reassignIncomesCategory(any(), any()))
        .thenAnswer((_) async => const Right(1));
    when(() => mockCategoryRepository.deleteCustomCategory(any(), any()))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, const Right(null));
    verify(
        () => mockExpenseRepository.reassignExpensesCategory(tCategoryId, tFallbackId));
    verify(
        () => mockIncomeRepository.reassignIncomesCategory(tCategoryId, tFallbackId));
    verify(
        () => mockCategoryRepository.deleteCustomCategory(tCategoryId, tFallbackId));
  });

  test('should rollback expense reassignment if income reassignment fails',
      () async {
    // arrange
    when(() => mockExpenseRepository.reassignExpensesCategory(any(), any()))
        .thenAnswer((_) async => const Right(1));
    when(() => mockIncomeRepository.reassignIncomesCategory(any(), any()))
        .thenAnswer((_) async => Left(ServerFailure('Fail')));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, Left(ServerFailure('Fail')));
    verify(
        () => mockExpenseRepository.reassignExpensesCategory(tCategoryId, tFallbackId));
    verify(
        () => mockIncomeRepository.reassignIncomesCategory(tCategoryId, tFallbackId));
    // Verify rollback
    verify(
        () => mockExpenseRepository.reassignExpensesCategory(tFallbackId, tCategoryId));
    verifyNever(
        () => mockCategoryRepository.deleteCustomCategory(any(), any()));
  });
}
