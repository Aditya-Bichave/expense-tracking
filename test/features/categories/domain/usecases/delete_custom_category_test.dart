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
  late DeleteCustomCategoryUseCase usecase;
  late MockCategoryRepository mockCategoryRepository;
  late MockExpenseRepository mockExpenseRepository;
  late MockIncomeRepository mockIncomeRepository;

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    mockExpenseRepository = MockExpenseRepository();
    mockIncomeRepository = MockIncomeRepository();
    usecase = DeleteCustomCategoryUseCase(
      mockCategoryRepository,
      mockExpenseRepository,
      mockIncomeRepository,
    );
  });

  const params = DeleteCustomCategoryParams(
    categoryId: 'old',
    fallbackCategoryId: 'new',
  );

  test(
    'rolls back expense reassignment when income reassignment fails',
    () async {
      when(
        () => mockExpenseRepository.reassignExpensesCategory(any(), any()),
      ).thenAnswer((_) async => const Right(1));
      when(
        () => mockIncomeRepository.reassignIncomesCategory(any(), any()),
      ).thenAnswer((_) async => const Left(ServerFailure('fail')));

      final result = await usecase(params);

      expect(result, equals(const Left(ServerFailure('fail'))));
      verify(
        () => mockExpenseRepository.reassignExpensesCategory('old', 'new'),
      ).called(1);
      verify(
        () => mockExpenseRepository.reassignExpensesCategory('new', 'old'),
      ).called(1);
      verifyNever(
        () => mockCategoryRepository.deleteCustomCategory(any(), any()),
      );
    },
  );

  test('deletes category when both reassignments succeed', () async {
    when(
      () => mockExpenseRepository.reassignExpensesCategory(any(), any()),
    ).thenAnswer((_) async => const Right(2));
    when(
      () => mockIncomeRepository.reassignIncomesCategory(any(), any()),
    ).thenAnswer((_) async => const Right(3));
    when(
      () => mockCategoryRepository.deleteCustomCategory(any(), any()),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase(params);

    expect(result, equals(const Right(null)));
    verify(
      () => mockExpenseRepository.reassignExpensesCategory('old', 'new'),
    ).called(1);
    verify(
      () => mockIncomeRepository.reassignIncomesCategory('old', 'new'),
    ).called(1);
    verify(
      () => mockCategoryRepository.deleteCustomCategory('old', 'new'),
    ).called(1);
  });
}
