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
  late MockCategoryRepository mockCategoryRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockIncomeRepository mockIncomeRepo;

  setUp(() {
    mockCategoryRepo = MockCategoryRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockIncomeRepo = MockIncomeRepository();
    usecase = DeleteCustomCategoryUseCase(
      mockCategoryRepo,
      mockExpenseRepo,
      mockIncomeRepo,
    );
  });

  test(
    'returns ValidationFailure when categoryId equals fallbackCategoryId',
    () async {
      const params = DeleteCustomCategoryParams(
        categoryId: 'cat1',
        fallbackCategoryId: 'cat1',
      );

      final result = await usecase(params);

      expect(
        result,
        equals(
          const Left(
            ValidationFailure('Category and fallback cannot be the same.'),
          ),
        ),
      );
      verifyZeroInteractions(mockCategoryRepo);
      verifyZeroInteractions(mockExpenseRepo);
      verifyZeroInteractions(mockIncomeRepo);
    },
  );
}
