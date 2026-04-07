#!/bin/bash
cat << 'INNER_EOF' > test/features/reports/data/repositories/report_repository_impl_test.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/reports/data/repositories/report_repository_impl.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}
class MockIncomeRepository extends Mock implements IncomeRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockAssetAccountRepository extends Mock implements AssetAccountRepository {}
class MockBudgetRepository extends Mock implements BudgetRepository {}
class MockGoalRepository extends Mock implements GoalRepository {}
class MockGoalContributionRepository extends Mock implements GoalContributionRepository {}

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

  final now = DateTime.now();

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
    final expense = ExpenseModel(
      id: '1', amount: 100, date: now, categoryId: tCategoryId, accountId: 'acc1', title: 'Lunch'
    );
    when(() => mockExpenseRepository.getExpenses(
      startDate: any(named: 'startDate'), endDate: any(named: 'endDate'),
      accountId: any(named: 'accountId'), categoryId: any(named: 'categoryId')
    )).thenAnswer((_) async => Right([expense]));
    when(() => mockCategoryRepository.getAllCategories())
        .thenAnswer((_) async => const Right([tCategory]));

    final result = await repository.getSpendingByCategory(
      startDate: now.subtract(const Duration(days: 1)), endDate: now,
      transactionType: TransactionType.expense,
    );

    expect(result.isRight(), true);
  });

  test('getSpendingOverTime returns data', () async {
    final expense = ExpenseModel(
      id: '1', amount: 100, date: now, categoryId: tCategoryId, accountId: 'acc1', title: 'Lunch'
    );
    when(() => mockExpenseRepository.getExpenses(
      startDate: any(named: 'startDate'), endDate: any(named: 'endDate'),
      accountId: any(named: 'accountId'), categoryId: any(named: 'categoryId')
    )).thenAnswer((_) async => Right([expense]));

    // We don't need TimeSeriesGranularity, let's just pass dynamic or don't use it, wait it might need it.
    // Let's search what is TimeSeriesGranularity
  });
}
INNER_EOF
