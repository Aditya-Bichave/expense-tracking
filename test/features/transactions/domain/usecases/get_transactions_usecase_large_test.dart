import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';

class MockExpenseRepo extends Mock implements ExpenseRepository {}

class MockIncomeRepo extends Mock implements IncomeRepository {}

class MockCategoryRepo extends Mock implements CategoryRepository {}

void main() {
  late GetTransactionsUseCase usecase;

  setUp(() {
    usecase = GetTransactionsUseCase(
      expenseRepository: MockExpenseRepo(),
      incomeRepository: MockIncomeRepo(),
      categoryRepository: MockCategoryRepo(),
    );
  });

  test('can be instantiated', () {
    expect(usecase, isNotNull);
  });
}
