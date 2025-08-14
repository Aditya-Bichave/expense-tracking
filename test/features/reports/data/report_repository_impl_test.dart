import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/reports/data/repositories/report_repository_impl.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockAccountRepository extends Mock implements AssetAccountRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockGoalRepository extends Mock implements GoalRepository {}

class MockGoalContributionRepository extends Mock
    implements GoalContributionRepository {}

void main() {
  late ReportRepositoryImpl repository;
  late MockGoalRepository goalRepository;
  late MockGoalContributionRepository contributionRepository;

  setUp(() {
    repository = ReportRepositoryImpl(
      expenseRepository: MockExpenseRepository(),
      incomeRepository: MockIncomeRepository(),
      categoryRepository: MockCategoryRepository(),
      accountRepository: MockAccountRepository(),
      budgetRepository: MockBudgetRepository(),
      goalRepository: goalRepository = MockGoalRepository(),
      goalContributionRepository: contributionRepository =
          MockGoalContributionRepository(),
    );
  });

  test('getGoalProgress aggregates contributions with single fetch', () async {
    final goal1 = Goal(
      id: 'g1',
      name: 'Goal 1',
      targetAmount: 100,
      status: GoalStatus.active,
      totalSaved: 0,
      createdAt: DateTime.now(),
    );
    final goal2 = Goal(
      id: 'g2',
      name: 'Goal 2',
      targetAmount: 200,
      status: GoalStatus.active,
      totalSaved: 0,
      createdAt: DateTime.now(),
    );

    when(
      () => goalRepository.getGoals(includeArchived: false),
    ).thenAnswer((_) async => Right([goal1, goal2]));

    final contributions = [
      GoalContribution(
        id: 'c1',
        goalId: 'g1',
        amount: 10,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
      GoalContribution(
        id: 'c2',
        goalId: 'g1',
        amount: 20,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
      GoalContribution(
        id: 'c3',
        goalId: 'g2',
        amount: 5,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ];
    when(
      () => contributionRepository.getAllContributions(),
    ).thenAnswer((_) async => Right(contributions));

    final result = await repository.getGoalProgress();
    expect(result.isRight(), true);
    final data = result.getOrElse(
      () => const GoalProgressReportData(progressData: []),
    );
    expect(data.progressData.length, 2);
    final g1Data = data.progressData.firstWhere((d) => d.goal.id == 'g1');
    expect(g1Data.contributions.length, 2);
    verify(() => contributionRepository.getAllContributions()).called(1);
  });
}
