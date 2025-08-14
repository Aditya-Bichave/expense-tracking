import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
import 'package:expense_tracker/features/categories/domain/usecases/categorize_transaction.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAddExpenseUseCase extends Mock implements AddExpenseUseCase {}

class MockUpdateExpenseUseCase extends Mock implements UpdateExpenseUseCase {}

class MockAddIncomeUseCase extends Mock implements AddIncomeUseCase {}

class MockUpdateIncomeUseCase extends Mock implements UpdateIncomeUseCase {}

class MockCategorizeTransactionUseCase extends Mock
    implements CategorizeTransactionUseCase {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      AddExpenseParams(
        Expense(
          id: '',
          title: '',
          amount: 0,
          date: DateTime(2024),
          accountId: 'a',
        ),
      ),
    );
    registerFallbackValue(
      UpdateExpenseParams(
        Expense(
          id: '',
          title: '',
          amount: 0,
          date: DateTime(2024),
          accountId: 'a',
        ),
      ),
    );
    registerFallbackValue(
      AddIncomeParams(
        Income(
          id: '',
          title: '',
          amount: 0,
          date: DateTime(2024),
          accountId: 'a',
        ),
      ),
    );
    registerFallbackValue(
      UpdateIncomeParams(
        Income(
          id: '',
          title: '',
          amount: 0,
          date: DateTime(2024),
          accountId: 'a',
        ),
      ),
    );
    registerFallbackValue(
      CategorizeTransactionParams(description: '', merchantId: null),
    );
  });

  group('AddEditTransactionBloc save failure', () {
    late MockAddExpenseUseCase addExpense;
    late MockUpdateExpenseUseCase updateExpense;
    late MockAddIncomeUseCase addIncome;
    late MockUpdateIncomeUseCase updateIncome;
    late MockCategorizeTransactionUseCase categorize;
    late MockExpenseRepository expenseRepo;
    late MockIncomeRepository incomeRepo;
    late MockCategoryRepository categoryRepo;

    setUp(() {
      addExpense = MockAddExpenseUseCase();
      updateExpense = MockUpdateExpenseUseCase();
      addIncome = MockAddIncomeUseCase();
      updateIncome = MockUpdateIncomeUseCase();
      categorize = MockCategorizeTransactionUseCase();
      expenseRepo = MockExpenseRepository();
      incomeRepo = MockIncomeRepository();
      categoryRepo = MockCategoryRepository();
    });

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'retains form data when save fails',
      build: () {
        when(
          () => addExpense(any()),
        ).thenAnswer((_) async => Left(ServerFailure('fail')));
        return AddEditTransactionBloc(
          addExpenseUseCase: addExpense,
          updateExpenseUseCase: updateExpense,
          addIncomeUseCase: addIncome,
          updateIncomeUseCase: updateIncome,
          categorizeTransactionUseCase: categorize,
          expenseRepository: expenseRepo,
          incomeRepository: incomeRepo,
          categoryRepository: categoryRepo,
        );
      },
      act: (bloc) => bloc.add(
        SaveTransactionRequested(
          title: 't',
          amount: 1.0,
          date: DateTime(2024),
          category: const Category(
            id: 'c1',
            name: 'c',
            iconName: 'i',
            colorHex: '#fff',
            type: CategoryType.expense,
            isCustom: true,
          ),
          accountId: 'a',
        ),
      ),
      expect: () => [
        isA<AddEditTransactionState>().having(
          (s) => s.status,
          'loading',
          AddEditStatus.loading,
        ),
        isA<AddEditTransactionState>().having(
          (s) => s.status,
          'saving',
          AddEditStatus.saving,
        ),
        isA<AddEditTransactionState>()
            .having((s) => s.status, 'error', AddEditStatus.error)
            .having((s) => s.tempTitle, 'title persists', 't')
            .having((s) => s.tempAmount, 'amount persists', 1.0),
      ],
    );
  });
}
