import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/reports/data/repositories/report_repository_impl.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
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

  group('getSpendingByCategory', () {
    const tCategoryId = 'cat1';
    const tCategory = Category(
      id: tCategoryId,
      name: 'Food',
      iconName: 'icon',
      colorHex: '#FFFFFF',
      type: CategoryType.expense,
      isCustom: false,
    );

    test('returns correct data when successful', () async {
      final now = DateTime(2023, 1, 2);
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

      final result = await repository.getSpendingByCategory(
        startDate: DateTime(2023, 1, 1),
        endDate: now,
        transactionType: TransactionType.expense,
      );

      expect(result.isRight(), true);
      result.fold((l) => fail('Should be right'), (data) {
        expect(data.currentTotalSpending, 100.0);
        expect(data.spendingByCategory.length, 1);
        expect(data.spendingByCategory.first.categoryId, tCategoryId);
        expect(data.spendingByCategory.first.categoryName, 'Food');
      });
    });

    test('returns empty data when no expenses found', () async {
      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => const Right([]));

      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => const Right([tCategory]));

      final result = await repository.getSpendingByCategory(
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 1, 2),
      );

      expect(result.isRight(), true);
      result.fold((l) => fail('Should be right'), (data) {
        expect(data.currentTotalSpending, 0.0);
        expect(data.spendingByCategory, isEmpty);
      });
    });

    test('returns failure when getExpenses fails', () async {
      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => Left(ServerFailure('Error')));

      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => const Right([tCategory]));

      final result = await repository.getSpendingByCategory(
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 1, 2),
      );

      expect(result, Left(ServerFailure('Error')));
    });
  });

  group('getGoalProgress', () {
    test('aggregates contributions with single fetch', () async {
      final goal1 = Goal(
        id: 'g1',
        name: 'Goal 1',
        targetAmount: 100,
        status: GoalStatus.active,
        totalSaved: 0,
        createdAt: DateTime(2023, 1, 1),
      );
      final goal2 = Goal(
        id: 'g2',
        name: 'Goal 2',
        targetAmount: 200,
        status: GoalStatus.active,
        totalSaved: 0,
        createdAt: DateTime(2023, 1, 1),
      );

      when(
        () => mockGoalRepository.getGoals(includeArchived: false),
      ).thenAnswer((_) async => Right([goal1, goal2]));

      final contributions = [
        GoalContribution(
          id: 'c1',
          goalId: 'g1',
          amount: 10,
          date: DateTime(2023, 1, 1),
          createdAt: DateTime(2023, 1, 1),
        ),
        GoalContribution(
          id: 'c2',
          goalId: 'g1',
          amount: 20,
          date: DateTime(2023, 1, 1),
          createdAt: DateTime(2023, 1, 1),
        ),
      ];
      when(
        () => mockGoalContributionRepository.getAllContributions(),
      ).thenAnswer((_) async => Right(contributions));

      final result = await repository.getGoalProgress();
      expect(result.isRight(), true);
      final data = result.getOrElse(
        () => const GoalProgressReportData(progressData: []),
      );
      expect(data.progressData.length, 2);
      final g1Data = data.progressData.firstWhere((d) => d.goal.id == 'g1');
      expect(g1Data.contributions.length, 2);
      verify(
        () => mockGoalContributionRepository.getAllContributions(),
      ).called(1);
    });

    test('returns failure when getGoals fails', () async {
      when(
        () => mockGoalRepository.getGoals(includeArchived: false),
      ).thenAnswer((_) async => Left(CacheFailure('Error')));

      when(
        () => mockGoalContributionRepository.getAllContributions(),
      ).thenAnswer((_) async => const Right([]));

      final result = await repository.getGoalProgress();

      expect(result.isLeft(), true);
    });
  });
}
