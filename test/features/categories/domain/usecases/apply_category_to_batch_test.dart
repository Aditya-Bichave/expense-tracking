import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/usecases/apply_category_to_batch.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

void main() {
  late ApplyCategoryToBatchUseCase usecase;
  late MockExpenseRepository mockExpenseRepository;
  late MockIncomeRepository mockIncomeRepository;

  setUpAll(() {
    registerFallbackValue(CategorizationStatus.categorized);
  });

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    mockIncomeRepository = MockIncomeRepository();
    usecase = ApplyCategoryToBatchUseCase(
      expenseRepository: mockExpenseRepository,
      incomeRepository: mockIncomeRepository,
    );
  });

  const tCategoryId = 'cat1';
  const tTxnId1 = 'txn1';
  const tTxnId2 = 'txn2';

  test('should update expense categorization for expense type', () async {
    // Arrange
    when(
      () => mockExpenseRepository.updateExpenseCategorization(
        any(),
        any(),
        any(),
        any(),
      ),
    ).thenAnswer((_) async => const Right(null));

    final params = ApplyCategoryToBatchParams(
      transactionIds: [tTxnId1, tTxnId2],
      categoryId: tCategoryId,
      transactionType: TransactionType.expense,
    );

    // Act
    final result = await usecase(params);

    // Assert
    expect(result, const Right(null));
    verify(
      () => mockExpenseRepository.updateExpenseCategorization(
        tTxnId1,
        tCategoryId,
        CategorizationStatus.categorized,
        null,
      ),
    ).called(1);
    verify(
      () => mockExpenseRepository.updateExpenseCategorization(
        tTxnId2,
        tCategoryId,
        CategorizationStatus.categorized,
        null,
      ),
    ).called(1);
    verifyZeroInteractions(mockIncomeRepository);
  });

  test('should update income categorization for income type', () async {
    // Arrange
    when(
      () => mockIncomeRepository.updateIncomeCategorization(
        any(),
        any(),
        any(),
        any(),
      ),
    ).thenAnswer((_) async => const Right(null));

    final params = ApplyCategoryToBatchParams(
      transactionIds: [tTxnId1],
      categoryId: tCategoryId,
      transactionType: TransactionType.income,
    );

    // Act
    final result = await usecase(params);

    // Assert
    expect(result, const Right(null));
    verify(
      () => mockIncomeRepository.updateIncomeCategorization(
        tTxnId1,
        tCategoryId,
        CategorizationStatus.categorized,
        null,
      ),
    ).called(1);
    verifyZeroInteractions(mockExpenseRepository);
  });

  test('should return failure if any update fails', () async {
    // Arrange
    when(
      () => mockExpenseRepository.updateExpenseCategorization(
        tTxnId1,
        any(),
        any(),
        any(),
      ),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockExpenseRepository.updateExpenseCategorization(
        tTxnId2,
        any(),
        any(),
        any(),
      ),
    ).thenAnswer((_) async => const Left(CacheFailure('Failed')));

    final params = ApplyCategoryToBatchParams(
      transactionIds: [tTxnId1, tTxnId2],
      categoryId: tCategoryId,
      transactionType: TransactionType.expense,
    );

    // Act
    final result = await usecase(params);

    // Assert
    expect(result.isLeft(), true);
    verify(
      () => mockExpenseRepository.updateExpenseCategorization(
        tTxnId1,
        any(),
        any(),
        any(),
      ),
    ).called(1);
    verify(
      () => mockExpenseRepository.updateExpenseCategorization(
        tTxnId2,
        any(),
        any(),
        any(),
      ),
    ).called(1);
  });
}
