import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/reports/data/repositories/report_repository_impl.dart';
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
  late MockBudgetRepository mockBudgetRepository;

  setUpAll(() {
    registerFallbackValue(DateTime(2023));
  });

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    mockBudgetRepository = MockBudgetRepository();

    // Stub unrelated repositories
    final mockIncomeRepository = MockIncomeRepository();
    final mockCategoryRepository = MockCategoryRepository();
    final mockAccountRepository = MockAssetAccountRepository();
    final mockGoalRepository = MockGoalRepository();
    final mockGoalContributionRepository = MockGoalContributionRepository();

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

  test(
    'getBudgetPerformance correctly filters and groups expenses by category',
    () async {
      // Arrange
      final startDate = DateTime(2023, 1, 1);
      final endDate = DateTime(2023, 1, 31);

      // Budget for "Food" (cat1)
      final budgetFood = Budget(
        id: 'b1',
        name: 'Food Budget',
        type: BudgetType.categorySpecific,
        targetAmount: 500,
        period: BudgetPeriodType.oneTime,
        startDate: startDate,
        endDate: endDate,
        categoryIds: ['cat1'],
        createdAt: DateTime.now(),
      );

      // Budget for "Transport" (cat2)
      final budgetTransport = Budget(
        id: 'b2',
        name: 'Transport Budget',
        type: BudgetType.categorySpecific,
        targetAmount: 300,
        period: BudgetPeriodType.oneTime,
        startDate: startDate,
        endDate: endDate,
        categoryIds: ['cat2'],
        createdAt: DateTime.now(),
      );

      // Budget Overall
      final budgetOverall = Budget(
        id: 'b3',
        name: 'Overall Budget',
        type: BudgetType.overall,
        targetAmount: 1000,
        period: BudgetPeriodType.oneTime,
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now(),
      );

      // Expenses
      final exp1 = ExpenseModel(
        id: 'e1',
        title: 'Lunch',
        amount: 50,
        date: DateTime(2023, 1, 10),
        categoryId: 'cat1',
        accountId: 'a1',
      );
      final exp2 = ExpenseModel(
        id: 'e2',
        title: 'Dinner',
        amount: 100,
        date: DateTime(2023, 1, 11),
        categoryId: 'cat1',
        accountId: 'a1',
      );
      final exp3 = ExpenseModel(
        id: 'e3',
        title: 'Taxi',
        amount: 20,
        date: DateTime(2023, 1, 12),
        categoryId: 'cat2',
        accountId: 'a1',
      );
      final exp4 = ExpenseModel(
        id: 'e4',
        title: 'Misc',
        amount: 10,
        date: DateTime(2023, 1, 13),
        categoryId: 'cat3',
        accountId: 'a1',
      ); // Unrelated category
      final expNullCat = ExpenseModel(
        id: 'e5',
        title: 'Unknown',
        amount: 5,
        date: DateTime(2023, 1, 14),
        categoryId: null,
        accountId: 'a1',
      ); // Null category

      when(() => mockBudgetRepository.getBudgets()).thenAnswer(
        (_) async => Right([budgetFood, budgetTransport, budgetOverall]),
      );
      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => Right([exp1, exp2, exp3, exp4, expNullCat]));

      // Act
      final result = await repository.getBudgetPerformance(
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should be right'), (report) {
        // Find results
        final foodResult = report.performanceData.firstWhere(
          (p) => p.budget.id == 'b1',
        );
        final transportResult = report.performanceData.firstWhere(
          (p) => p.budget.id == 'b2',
        );
        final overallResult = report.performanceData.firstWhere(
          (p) => p.budget.id == 'b3',
        );

        // Check Food: exp1 + exp2 = 150
        expect(foodResult.actualSpending.currentValue, 150.0);

        // Check Transport: exp3 = 20
        expect(transportResult.actualSpending.currentValue, 20.0);

        // Check Overall: exp1 + exp2 + exp3 + exp4 + expNullCat = 185
        expect(overallResult.actualSpending.currentValue, 185.0);
      });
    },
  );
}
