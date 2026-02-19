import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/reports/data/repositories/report_repository_impl.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockAssetAccountRepository extends Mock
    implements AssetAccountRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockGoalRepository extends Mock implements GoalRepository {}

class MockGoalContributionRepository extends Mock
    implements GoalContributionRepository {}

void main() {
  late ReportRepositoryImpl repository;
  late MockExpenseRepository mockExpenseRepository;
  late MockIncomeRepository mockIncomeRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockAssetAccountRepository mockAccountRepository;
  late MockBudgetRepository mockBudgetRepository;
  late MockGoalRepository mockGoalRepository;
  late MockGoalContributionRepository mockGoalContributionRepository;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    mockIncomeRepository = MockIncomeRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockAccountRepository = MockAssetAccountRepository();
    mockBudgetRepository = MockBudgetRepository();
    mockGoalRepository = MockGoalRepository();
    mockGoalContributionRepository = MockGoalContributionRepository();

    repository = ReportRepositoryImpl(
      expenseRepository: mockExpenseRepository,
      incomeRepository: mockIncomeRepository,
      categoryRepository: mockCategoryRepository,
      accountRepository: mockAccountRepository,
      budgetRepository: mockBudgetRepository,
      goalRepository: mockGoalRepository,
      goalContributionRepository: mockGoalContributionRepository,
    );
  });

  const tCategoryId = 'cat1';
  const tCategory = Category(
    id: tCategoryId,
    name: 'Food',
    iconName: 'icon',
    colorHex: '#FFFFFF',
    type: CategoryType.expense,
    isCustom: false,
  );

  test('getSpendingByCategory returns correct data', () async {
    // Arrange
    final now = DateTime.now();
    final expense = ExpenseModel(
      id: '1',
      amount: 100,
      date: now,
      categoryId: tCategoryId,
      accountId: 'acc1',
      title: 'Lunch',
    );

    when(
      () => mockExpenseRepository.getExpenses(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        accountId: any(named: 'accountId'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => Right([expense]));

    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => const Right([tCategory]));

    // Act
    final result = await repository.getSpendingByCategory(
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now,
      transactionType: TransactionType.expense,
    );

    // Assert
    expect(result.isRight(), true);
    result.fold((l) => fail('Should be right'), (data) {
      expect(data.currentTotalSpending, 100.0);
      expect(data.spendingByCategory.length, 1);
      expect(data.spendingByCategory.first.categoryId, tCategoryId);
      expect(data.spendingByCategory.first.categoryName, 'Food');
    });
  });

  test('getSpendingByCategory returns empty if no expenses', () async {
    // Arrange
    when(
      () => mockExpenseRepository.getExpenses(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        accountId: any(named: 'accountId'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => const Right([]));

    // Act
    final result = await repository.getSpendingByCategory(
      startDate: DateTime.now(),
      endDate: DateTime.now(),
    );

    // Assert
    expect(result.isRight(), true);
    result.fold((l) => fail('Should be right'), (data) {
      expect(data.currentTotalSpending, 0.0);
      expect(data.spendingByCategory, isEmpty);
    });
  });
}
