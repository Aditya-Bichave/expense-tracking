import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/reports/data/repositories/report_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';

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
  late MockExpenseRepository mockExpenseRepo;
  late MockIncomeRepository mockIncomeRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockAssetAccountRepository mockAccountRepo;
  late MockBudgetRepository mockBudgetRepo;
  late MockGoalRepository mockGoalRepo;
  late MockGoalContributionRepository mockGoalContributionRepo;

  setUp(() {
    mockExpenseRepo = MockExpenseRepository();
    mockIncomeRepo = MockIncomeRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockAccountRepo = MockAssetAccountRepository();
    mockBudgetRepo = MockBudgetRepository();
    mockGoalRepo = MockGoalRepository();
    mockGoalContributionRepo = MockGoalContributionRepository();

    repository = ReportRepositoryImpl(
      expenseRepository: mockExpenseRepo,
      incomeRepository: mockIncomeRepo,
      categoryRepository: mockCategoryRepo,
      accountRepository: mockAccountRepo,
      budgetRepository: mockBudgetRepo,
      goalRepository: mockGoalRepo,
      goalContributionRepository: mockGoalContributionRepo,
    );
  });

  group('getRecentDailyContributions', () {
    final tGoalId = 'goal-123';

    test('should return aggregated contributions correctly', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final List<GoalContribution> tContributions = [
        GoalContribution(
          id: '1',
          goalId: tGoalId,
          amount: 100,
          date: today,
          createdAt: today,
        ),
        GoalContribution(
          id: '2',
          goalId: tGoalId,
          amount: 50,
          date: today,
          createdAt: today,
        ),
        GoalContribution(
          id: '3',
          goalId: tGoalId,
          amount: 200,
          date: yesterday,
          createdAt: yesterday,
        ),
        // Out of bounds - should be filtered out
        GoalContribution(
          id: '4',
          goalId: tGoalId,
          amount: 300,
          date: today.subtract(const Duration(days: 10)),
          createdAt: today,
        ),
      ];

      when(
        () => mockGoalContributionRepo.getContributionsForGoal(tGoalId),
      ).thenAnswer((_) async => Right(tContributions));

      final result = await repository.getRecentDailyContributions(
        tGoalId,
        days: 7,
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should not fail'), (data) {
        expect(data.length, 7);

        // Check last day (today)
        expect(data.last.date.year, today.year);
        expect(data.last.date.month, today.month);
        expect(data.last.date.day, today.day);
        expect(data.last.amount.currentValue, 150.0);

        // Check yesterday
        expect(data[data.length - 2].date.day, yesterday.day);
        expect(data[data.length - 2].amount.currentValue, 200.0);

        // Check an older day within the 7 days but with no contributions
        expect(data.first.amount.currentValue, 0.0);
      });
    });

    test('returns Failure when repo fails', () async {
      when(
        () => mockGoalContributionRepo.getContributionsForGoal(tGoalId),
      ).thenAnswer((_) async => const Left(CacheFailure('Failed')));

      final result = await repository.getRecentDailyContributions(
        tGoalId,
        days: 7,
      );
      expect(result.isLeft(), true);
    });

    test('returns Failure on unexpected exception', () async {
      when(
        () => mockGoalContributionRepo.getContributionsForGoal(tGoalId),
      ).thenThrow(Exception('test'));

      final result = await repository.getRecentDailyContributions(
        tGoalId,
        days: 7,
      );
      expect(result.isLeft(), true);
    });
  });
}
