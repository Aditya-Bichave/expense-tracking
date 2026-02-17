import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late GetTransactionsUseCase useCase;
  late MockExpenseRepository mockExpenseRepository;
  late MockIncomeRepository mockIncomeRepository;
  late MockCategoryRepository mockCategoryRepository;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    mockIncomeRepository = MockIncomeRepository();
    mockCategoryRepository = MockCategoryRepository();
    useCase = GetTransactionsUseCase(
      expenseRepository: mockExpenseRepository,
      incomeRepository: mockIncomeRepository,
      categoryRepository: mockCategoryRepository,
    );
  });

  final tDate = DateTime(2023, 1, 1);
  final tExpenseModel = ExpenseModel(
    id: 'e1',
    title: 'Expense 1',
    amount: 100.0,
    date: tDate,
    accountId: 'acc1',
    categoryId: 'cat1',
  );
  final tIncomeModel = IncomeModel(
    id: 'i1',
    title: 'Income 1',
    amount: 200.0,
    date: tDate,
    accountId: 'acc1',
    categoryId: 'cat2',
  );

  final tCategory1 = Category(
    id: 'cat1',
    name: 'Food',
    type: CategoryType.expense,
    iconName: 'food',
    colorHex: '#FFFFFF',
    isCustom: false,
  );

  final tCategory2 = Category(
    id: 'cat2',
    name: 'Salary',
    type: CategoryType.income,
    iconName: 'money',
    colorHex: '#FFFFFF',
    isCustom: false,
  );

  test('should return combined list of transactions', () async {
    // arrange
    when(() => mockCategoryRepository.getAllCategories())
        .thenAnswer((_) async => Right([tCategory1, tCategory2]));
    when(() => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        )).thenAnswer((_) async => Right([tExpenseModel]));
    when(() => mockIncomeRepository.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        )).thenAnswer((_) async => Right([tIncomeModel]));

    // act
    final result = await useCase(const GetTransactionsParams());

    // assert
    expect(result.isRight(), true);
    final list = result.getOrElse(() => []);
    expect(list.length, 2);
    expect(list.any((t) => t.id == 'e1'), true);
    expect(list.any((t) => t.id == 'i1'), true);

    // Check hydration
    final expense = list.firstWhere((t) => t.id == 'e1');
    expect(expense.category?.name, 'Food');

    final income = list.firstWhere((t) => t.id == 'i1');
    expect(income.category?.name, 'Salary');
  });

  test('should return filtered transactions (Expense only)', () async {
    // arrange
    when(() => mockCategoryRepository.getAllCategories())
        .thenAnswer((_) async => Right([tCategory1]));
    when(() => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        )).thenAnswer((_) async => Right([tExpenseModel]));

    // act
    final result = await useCase(const GetTransactionsParams(
      transactionType: TransactionType.expense,
    ));

    // assert
    expect(result.isRight(), true);
    final list = result.getOrElse(() => []);
    expect(list.length, 1);
    expect(list.first.id, 'e1');
    verifyNever(() => mockIncomeRepository.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
    ));
  });

  test('should return filtered transactions (Search term)', () async {
    // arrange
    when(() => mockCategoryRepository.getAllCategories())
        .thenAnswer((_) async => Right([tCategory1, tCategory2]));
    when(() => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
    )).thenAnswer((_) async => Right([tExpenseModel]));
    when(() => mockIncomeRepository.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
    )).thenAnswer((_) async => Right([tIncomeModel]));

    // act
    final result = await useCase(const GetTransactionsParams(
      searchTerm: 'Expense',
    ));

    // assert
    expect(result.isRight(), true);
    final list = result.getOrElse(() => []);
    expect(list.length, 1);
    expect(list.first.title, 'Expense 1');
  });

  test('should handle repository failure (Categories)', () async {
    // arrange
    when(() => mockCategoryRepository.getAllCategories())
        .thenAnswer((_) async => Left(CacheFailure()));
    // Mock repositories are still called to construct the future list, so we need to mock them returning something or nothing.
    // The usecase builds the future list *before* awaiting.
    // So expenseRepository.getExpenses IS called.
    when(() => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
    )).thenAnswer((_) async => const Right([]));
    when(() => mockIncomeRepository.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
    )).thenAnswer((_) async => const Right([]));

    // act
    final result = await useCase(const GetTransactionsParams());

    // assert
    expect(result.isLeft(), true);
  });

  test('should handle repository failure (Expenses)', () async {
      // arrange
      when(() => mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => Right([]));
      when(() => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
      )).thenAnswer((_) async => Left(CacheFailure()));
      when(() => mockIncomeRepository.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
      )).thenAnswer((_) async => Right([]));

      // act
      final result = await useCase(const GetTransactionsParams());

      // assert
      expect(result.isLeft(), true);
    });
}
