// lib/features/dashboard/domain/usecases/get_financial_overview.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart'; // For TimeSeriesDataPoint
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart'; // Import Report Repo
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart'; // For Colors in BudgetStatus calc
import 'package:expense_tracker/core/di/service_locator.dart'; // For sl
// Explicit Import for AssetAccount to solve type error
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';

class GetFinancialOverviewUseCase
    implements UseCase<FinancialOverview, GetFinancialOverviewParams> {
  final AssetAccountRepository accountRepository;
  final IncomeRepository incomeRepository;
  final ExpenseRepository expenseRepository;
  final BudgetRepository budgetRepository;
  final GoalRepository goalRepository;
  final ReportRepository reportRepository;

  GetFinancialOverviewUseCase({
    required this.accountRepository,
    required this.incomeRepository,
    required this.expenseRepository,
    required this.budgetRepository,
    required this.goalRepository,
    required this.reportRepository,
  });

  @override
  Future<Either<Failure, FinancialOverview>> call(
    GetFinancialOverviewParams params,
  ) async {
    log.info(
      "Executing GetFinancialOverviewUseCase. Start: ${params.startDate}, End: ${params.endDate}",
    );
    try {
      // Execute all independent fetches in parallel using Future.wait
      final results = await Future.wait([
        // 0. Accounts
        accountRepository.getAssetAccounts(),
        // 1. Total Income
        incomeRepository.getTotalIncomeForAccount(
          '',
          startDate: params.startDate,
          endDate: params.endDate,
        ),
        // 2. Total Expenses
        expenseRepository.getTotalExpensesForAccount(
          '',
          startDate: params.startDate,
          endDate: params.endDate,
        ),
        // 3. Budgets
        _getBudgetSummary(),
        // 4. Goals
        _getGoalSummary(),
        // 5. Recent Spending
        reportRepository.getRecentDailySpending(days: 7),
      ]);

      // --- Process 0: Accounts ---
      // Re-fetch individual results with proper casting
      final accountsResult = results[0] as Either<Failure, List<AssetAccount>>; // Generic List
      final incomeResult = results[1] as Either<Failure, double>;
      final expenseResult = results[2] as Either<Failure, double>;
      final budgetSummary = results[3] as List<BudgetWithStatus>;
      final goalSummary = results[4] as List<Goal>;
      final recentSpendingEither =
          results[5] as Either<Failure, List<TimeSeriesDataPoint>>;

      if (accountsResult.isLeft())
        return _handleFailure("accounts", accountsResult);

      final accounts =
          accountsResult.fold((_) => <AssetAccount>[], (list) => list);

      double overallBalance = 0.0;
      final Map<String, double> accountBalancesMap = {};

      for (final acc in accounts) {
        final balance = acc.currentBalance;
        final name = acc.name;
        overallBalance += balance;
        accountBalancesMap[name] = balance;
      }

      // --- Process Income/Expense ---
      if (incomeResult.isLeft()) {
        return _handleFailure("total income", incomeResult);
      }
      final totalIncome = incomeResult.getOrElse(() => 0.0);

      if (expenseResult.isLeft()) {
        return _handleFailure("total expenses", expenseResult);
      }
      final totalExpenses = expenseResult.getOrElse(() => 0.0);

      final netFlow = totalIncome - totalExpenses;

      // --- Process Recent Spending ---
      final recentSpendingData = recentSpendingEither.fold((l) {
        log.warning(
          "[GetFinancialOverviewUseCase] Failed fetch spending sparkline: ${l.message}",
        );
        return <TimeSeriesDataPoint>[];
      }, (r) => r);

      // --- Fetch Contribution Sparkline (Dependent on Goal Summary) ---
      List<TimeSeriesDataPoint> recentContributionData = [];
      if (goalSummary.isNotEmpty) {
        log.fine(
          "[GetFinancialOverviewUseCase] Fetching recent contributions for top goal sparkline: ${goalSummary.first.id}...",
        );
        final recentContribEither = await reportRepository
            .getRecentDailyContributions(goalSummary.first.id, days: 30);
        recentContributionData = recentContribEither.fold((l) {
          log.warning(
            "[GetFinancialOverviewUseCase] Failed fetch contribution sparkline: ${l.message}",
          );
          return <TimeSeriesDataPoint>[];
        }, (r) => r);
      }

      // 8. Construct the overview object
      final overview = FinancialOverview(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        netFlow: netFlow,
        overallBalance: overallBalance,
        accounts: accounts,
        accountBalances: accountBalancesMap,
        activeBudgetsSummary: budgetSummary,
        activeGoalsSummary: goalSummary,
        recentSpendingSparkline: recentSpendingData,
        recentContributionSparkline: recentContributionData,
      );

      log.info(
        "[GetFinancialOverviewUseCase] Successfully created FinancialOverview. Returning Right.",
      );
      return Right(overview);
    } catch (e, s) {
      log.severe("[GetFinancialOverviewUseCase] Unexpected error$e$s");
      return Left(
        UnexpectedFailure(
          'Failed to generate financial overview: ${e.toString()}',
        ),
      );
    }
  }

  // --- Helper Methods (Unchanged from previous, except _getRecentSpendingData) ---
  Left<Failure, FinancialOverview> _handleFailure(
    String context,
    Either<dynamic, dynamic> either,
  ) {
    // We know the left side is Failure
    Failure? failure;
    if (either.isLeft()) {
      either.fold((l) => failure = l as Failure, (_) {});
      // failure is assigned
      return Left(failure!);
    }
    return Left(UnexpectedFailure("Incorrect failure handling logic"));
  }

  Future<List<BudgetWithStatus>> _getBudgetSummary() async {
    List<BudgetWithStatus> budgetStatuses = [];
    Failure? budgetError;
    final budgetsResult = await budgetRepository.getBudgets();

    // Check failure first
    if(budgetsResult.isLeft()) {
         budgetsResult.fold((f) => budgetError = f, (_) {});
          log.warning(
            "[GetFinancialOverviewUseCase] Error fetching budgets: ${budgetError!.message}",
          );
         return [];
    }

    final budgets = budgetsResult.getOrElse(() => []);
    if(budgets.isEmpty) return [];

    // Parallelize budget spent calculations
    const thrivingColor = Colors.green;
    const nearingLimitColor = Colors.orange;
    const overLimitColor = Colors.red;

    final spentFutures = budgets.map((budget) {
      final (periodStart, periodEnd) = budget.getCurrentPeriodDates();
      return budgetRepository.calculateAmountSpent(
          budget: budget,
          periodStart: periodStart,
          periodEnd: periodEnd,
        ).then((result) => (budget, result));
    });

    final results = await Future.wait(spentFutures);

    for (final (budget, spentResult) in results) {
        spentResult.fold(
          (f) {
            log.warning(
              "[GetFinancialOverviewUseCase] Failed calc for budget ${budget.id}: ${f.message}",
            );
            // We continue even if one fails
          },
          (spent) {
            budgetStatuses.add(
              BudgetWithStatus.calculate(
                budget: budget,
                amountSpent: spent,
                thrivingColor: thrivingColor,
                nearingLimitColor: nearingLimitColor,
                overLimitColor: overLimitColor,
              ),
            );
          },
        );
    }

    budgetStatuses.sort((a, b) => b.percentageUsed.compareTo(a.percentageUsed));
    return budgetStatuses.take(3).toList(); // Take top 3 most used/overspent
  }

  Future<List<Goal>> _getGoalSummary() async {
    Failure? goalError;
    List<Goal> goalSummary = [];
    final goalsResult = await goalRepository.getGoals(
      includeArchived: false,
    ); // Only active goals
    goalsResult.fold((failure) => goalError = failure, (activeGoals) {
      // Sort by most complete first, then soonest target date
      final mutableGoals = List<Goal>.from(activeGoals);
      mutableGoals.sort((a, b) {
        int comparison = b.percentageComplete.compareTo(a.percentageComplete);
        if (comparison == 0) {
          comparison = (a.targetDate ?? DateTime(2100)).compareTo(
            b.targetDate ?? DateTime(2100),
          );
        }
        return comparison;
      });
      goalSummary = mutableGoals
          .take(3)
          .toList(); // Take top 3 most complete / closest target
    });
    if (goalError != null) {
      log.warning(
        "[GetFinancialOverviewUseCase] Error fetching goals: ${goalError!.message}",
      );
    }
    return goalSummary;
  }
}

class GetFinancialOverviewParams extends Equatable {
  final DateTime? startDate; // Period for Income/Expense/NetFlow totals
  final DateTime? endDate;

  const GetFinancialOverviewParams({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
