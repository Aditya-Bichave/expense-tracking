import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/main.dart'; // Logger
import 'package:flutter/material.dart'; // Colors

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
      log.fine("[GetFinancialOverviewUseCase] Fetching accounts...");
      final accountsEither = await accountRepository.getAssetAccounts();
      if (accountsEither.isLeft())
        return _handleFailure("accounts", accountsEither);
      final accounts = accountsEither.getOrElse(() => []);
      log.fine(
        "[GetFinancialOverviewUseCase] Fetched ${accounts.length} accounts.",
      );

      final double overallBalance = accounts.fold(
        0.0,
        (sum, acc) => sum + acc.currentBalance,
      );
      log.fine(
        "[GetFinancialOverviewUseCase] Calculated overall balance: $overallBalance",
      );

      final Map<String, double> accountBalancesMap = {
        for (var acc in accounts) acc.name: acc.currentBalance,
      };
      log.fine(
        "[GetFinancialOverviewUseCase] Created account balances map (${accountBalancesMap.length} entries).",
      );

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

      log.fine(
        "[GetFinancialOverviewUseCase] Fetching budgets and calculating statuses...",
      );
      List<BudgetWithStatus> budgetSummary = await _getBudgetSummary();
      log.fine(
        "[GetFinancialOverviewUseCase] Prepared budget summary with ${budgetSummary.length} items.",
      );

      log.fine(
        "[GetFinancialOverviewUseCase] Fetching active goals summary...",
      );
      List<Goal> goalSummary = await _getGoalSummary();
      log.fine(
        "[GetFinancialOverviewUseCase] Prepared goal summary with ${goalSummary.length} items.",
      );

      log.fine(
        "[GetFinancialOverviewUseCase] Fetching recent spending for sparklines...",
      );
      final recentSpendingEither = await reportRepository
          .getRecentDailySpending(days: 7);
      final recentSpendingData = recentSpendingEither.fold((l) {
        log.warning(
          "[GetFinancialOverviewUseCase] Failed fetch spending sparkline: ${l.message}",
        );
        return <TimeSeriesDataPoint>[];
      }, (r) => r);
      log.fine(
        "[GetFinancialOverviewUseCase] Fetched ${recentSpendingData.length} points for spending sparkline.",
      );

      List<TimeSeriesDataPoint> recentContributionData = [];
      if (goalSummary.isNotEmpty) {
        log.fine(
          "[GetFinancialOverviewUseCase] Fetching recent contributions for top goal sparkline: ${goalSummary.first.id}...",
        );
        final recentContribEither = await reportRepository
            .getRecentDailyContributions(
              goalSummary.first.id,
              days: 30,
            );
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
        recentContributionSparkline:
            recentContributionData,
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
    return budgetStatuses.take(3).toList();
  }

  Future<List<Goal>> _getGoalSummary() async {
    Failure? goalError;
    List<Goal> goalSummary = [];
    final goalsResult = await goalRepository.getGoals(
      includeArchived: false,
    );
    goalsResult.fold((failure) => goalError = failure, (activeGoals) {
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
          .toList();
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
  final DateTime? startDate;
  final DateTime? endDate;

  const GetFinancialOverviewParams({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
