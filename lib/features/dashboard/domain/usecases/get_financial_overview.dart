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
import 'package:expense_tracker/core/utils/logger.dart';

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
      // 1. Get accounts
      log.fine("[GetFinancialOverviewUseCase] Fetching accounts...");
      final accountsEither = await accountRepository.getAssetAccounts();
      if (accountsEither.isLeft())
        return _handleFailure("accounts", accountsEither);
      final accounts = accountsEither.getOrElse(() => []);
      log.fine(
        "[GetFinancialOverviewUseCase] Fetched ${accounts.length} accounts.",
      );

      // 2. Calculate overall balance
      final double overallBalance = accounts.fold(
        0.0,
        (sum, acc) => sum + acc.currentBalance,
      );
      log.fine(
        "[GetFinancialOverviewUseCase] Calculated overall balance: $overallBalance",
      );

      // 3. Create account balances map
      final Map<String, double> accountBalancesMap = {
        for (var acc in accounts) acc.name: acc.currentBalance,
      };
      log.fine(
        "[GetFinancialOverviewUseCase] Created account balances map (${accountBalancesMap.length} entries).",
      );

      // 4. Get total income/expenses for the period
      log.fine(
        "[GetFinancialOverviewUseCase] Fetching total income/expenses for period...",
      );
      final incomeResult = await incomeRepository.getTotalIncomeForAccount(
        '',
        startDate: params.startDate,
        endDate: params.endDate,
      );
      if (incomeResult.isLeft()) {
        final failure = incomeResult.swap().getOrElse(
          () => const UnexpectedFailure('Unknown income failure'),
        );
        log.warning(
          "[GetFinancialOverviewUseCase] Failed to get total income: ${failure.message}",
        );
        return Left(failure);
      }
      final expenseResult = await expenseRepository.getTotalExpensesForAccount(
        '',
        startDate: params.startDate,
        endDate: params.endDate,
      );
      if (expenseResult.isLeft()) {
        final failure = expenseResult.swap().getOrElse(
          () => const UnexpectedFailure('Unknown expense failure'),
        );
        log.warning(
          "[GetFinancialOverviewUseCase] Failed to get total expenses: ${failure.message}",
        );
        return Left(failure);
      }
      final totalIncome = incomeResult.getOrElse(() => 0.0);
      final totalExpenses = expenseResult.getOrElse(() => 0.0);
      final netFlow = totalIncome - totalExpenses;
      log.fine(
        "[GetFinancialOverviewUseCase] Period Totals - Income: $totalIncome, Expenses: $totalExpenses, Net Flow: $netFlow",
      );

      // 5. Fetch Budget Statuses
      log.fine(
        "[GetFinancialOverviewUseCase] Fetching budgets and calculating statuses...",
      );
      List<BudgetWithStatus> budgetSummary = await _getBudgetSummary();
      log.fine(
        "[GetFinancialOverviewUseCase] Prepared budget summary with ${budgetSummary.length} items.",
      );

      // 6. Fetch Goal Summary
      log.fine(
        "[GetFinancialOverviewUseCase] Fetching active goals summary...",
      );
      List<Goal> goalSummary = await _getGoalSummary();
      log.fine(
        "[GetFinancialOverviewUseCase] Prepared goal summary with ${goalSummary.length} items.",
      );

      // --- 7. Fetch Recent Spending & Contribution Data ---
      log.fine(
        "[GetFinancialOverviewUseCase] Fetching recent spending for sparklines...",
      );
      final recentSpendingEither = await reportRepository
          .getRecentDailySpending(days: 7); // Last 7 days
      final recentSpendingData = recentSpendingEither.fold((l) {
        log.warning(
          "[GetFinancialOverviewUseCase] Failed fetch spending sparkline: ${l.message}",
        );
        return <TimeSeriesDataPoint>[];
      }, (r) => r);
      log.fine(
        "[GetFinancialOverviewUseCase] Fetched ${recentSpendingData.length} points for spending sparkline.",
      );

      // Fetch contribution sparkline data (e.g., for the top goal if available)
      List<TimeSeriesDataPoint> recentContributionData = [];
      if (goalSummary.isNotEmpty) {
        log.fine(
          "[GetFinancialOverviewUseCase] Fetching recent contributions for top goal sparkline: ${goalSummary.first.id}...",
        );
        final recentContribEither = await reportRepository
            .getRecentDailyContributions(
              goalSummary.first.id,
              days: 30,
            ); // Last 30 days for goals
        recentContributionData = recentContribEither.fold((l) {
          log.warning(
            "[GetFinancialOverviewUseCase] Failed fetch contribution sparkline: ${l.message}",
          );
          return <TimeSeriesDataPoint>[];
        }, (r) => r);
        log.fine(
          "[GetFinancialOverviewUseCase] Fetched ${recentContributionData.length} points for contribution sparkline.",
        );
      }
      // --- End Fetch Sparkline Data ---

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
        recentSpendingSparkline: recentSpendingData, // Use refined data
        recentContributionSparkline:
            recentContributionData, // Add contribution data
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
    Either<Failure, dynamic> either,
  ) {
    final failure = either.fold(
      (l) => l,
      (_) => const UnexpectedFailure("Incorrect fold logic"),
    );
    log.warning(
      "[GetFinancialOverviewUseCase] Failed to fetch $context: ${failure.message}",
    );
    return Left(failure);
  }

  Future<List<BudgetWithStatus>> _getBudgetSummary() async {
    List<BudgetWithStatus> budgetStatuses = [];
    Failure? budgetError;
    final budgetsResult = await budgetRepository.getBudgets();
    await budgetsResult.fold((failure) async => budgetError = failure, (
      budgets,
    ) async {
      const thrivingColor = Colors.green;
      const nearingLimitColor = Colors.orange;
      const overLimitColor = Colors.red;
      for (final budget in budgets) {
        final (periodStart, periodEnd) = budget.getCurrentPeriodDates();
        final spentResult = await budgetRepository.calculateAmountSpent(
          budget: budget,
          periodStart: periodStart,
          periodEnd: periodEnd,
        );
        spentResult.fold(
          (f) {
            log.warning(
              "[GetFinancialOverviewUseCase] Failed calc for budget ${budget.id}: ${f.message}",
            );
            budgetError ??= f;
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
        if (budgetError != null && budgetError is! ValidationFailure) break;
      }
    });
    if (budgetError != null) {
      log.warning(
        "[GetFinancialOverviewUseCase] Error during budget status calculation: ${budgetError!.message}",
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
