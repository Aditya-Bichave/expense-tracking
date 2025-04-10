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
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // For sl

class GetFinancialOverviewUseCase
    implements UseCase<FinancialOverview, GetFinancialOverviewParams> {
  final AssetAccountRepository accountRepository;
  final IncomeRepository incomeRepository;
  final ExpenseRepository expenseRepository;
  final BudgetRepository budgetRepository;
  final GoalRepository goalRepository;
  // --- ADDED Report Repository for Sparkline Data ---
  ReportRepository get reportRepository => sl<ReportRepository>();

  GetFinancialOverviewUseCase({
    required this.accountRepository,
    required this.incomeRepository,
    required this.expenseRepository,
    required this.budgetRepository,
    required this.goalRepository,
  });

  @override
  Future<Either<Failure, FinancialOverview>> call(
      GetFinancialOverviewParams params) async {
    log.info(
        "Executing GetFinancialOverviewUseCase. Start: ${params.startDate}, End: ${params.endDate}");
    try {
      // 1. Get accounts (unchanged)
      log.info("[GetFinancialOverviewUseCase] Fetching accounts...");
      final accountsEither = await accountRepository.getAssetAccounts();
      if (accountsEither.isLeft())
        return _handleFailure("accounts", accountsEither);
      final accounts = accountsEither.getOrElse(() => []);
      log.info(
          "[GetFinancialOverviewUseCase] Fetched ${accounts.length} accounts.");

      // 2. Calculate overall balance (unchanged)
      final double overallBalance =
          accounts.fold(0.0, (sum, acc) => sum + acc.currentBalance);
      log.info(
          "[GetFinancialOverviewUseCase] Calculated overall balance: $overallBalance");

      // 3. Create account balances map (unchanged)
      final Map<String, double> accountBalancesMap = {
        for (var acc in accounts) acc.name: acc.currentBalance
      };
      log.info(
          "[GetFinancialOverviewUseCase] Created account balances map (${accountBalancesMap.length} entries).");

      // 4. Get total income/expenses for the period (unchanged)
      log.info(
          "[GetFinancialOverviewUseCase] Fetching total income/expenses for period...");
      final incomeResult = await incomeRepository.getTotalIncomeForAccount('',
          startDate: params.startDate, endDate: params.endDate);
      final expenseResult = await expenseRepository.getTotalExpensesForAccount(
          '',
          startDate: params.startDate,
          endDate: params.endDate);
      final totalIncome = incomeResult.fold(
          (l) => _logAndDefault(l, "total income", 0.0), (r) => r);
      final totalExpenses = expenseResult.fold(
          (l) => _logAndDefault(l, "total expenses", 0.0), (r) => r);
      final netFlow = totalIncome - totalExpenses;
      log.info(
          "[GetFinancialOverviewUseCase] Period Totals - Income: $totalIncome, Expenses: $totalExpenses, Net Flow: $netFlow");

      // --- 5. Fetch Budget Statuses (Unchanged) ---
      log.info(
          "[GetFinancialOverviewUseCase] Fetching budgets and calculating statuses...");
      List<BudgetWithStatus> budgetSummary = await _getBudgetSummary();
      log.info(
          "[GetFinancialOverviewUseCase] Prepared budget summary with ${budgetSummary.length} items.");

      // --- 6. Fetch Goal Summary (Unchanged) ---
      log.info(
          "[GetFinancialOverviewUseCase] Fetching active goals summary...");
      List<Goal> goalSummary = await _getGoalSummary();
      log.info(
          "[GetFinancialOverviewUseCase] Prepared goal summary with ${goalSummary.length} items.");

      // --- 7. Fetch Recent Spending Data (Placeholder/Basic Implementation) ---
      // TODO: Enhance ReportRepository for more efficient daily fetching if needed
      log.info(
          "[GetFinancialOverviewUseCase] Fetching recent spending for sparklines...");
      final recentSpendingData = await _getRecentSpendingData();
      log.info(
          "[GetFinancialOverviewUseCase] Fetched ${recentSpendingData.length} points for sparkline.");

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
        recentSpendingSparkline: recentSpendingData, // Added
      );
      log.info(
          "[GetFinancialOverviewUseCase] Successfully created FinancialOverview. Returning Right.");
      return Right(overview);
    } catch (e, s) {
      log.severe("[GetFinancialOverviewUseCase] Unexpected error$e$s");
      return Left(UnexpectedFailure(
          'Failed to generate financial overview: ${e.toString()}'));
    }
  }

  // --- Helper Methods (Unchanged) ---
  Left<Failure, FinancialOverview> _handleFailure(
      String context, Either<Failure, dynamic> either) {
    final failure = either.fold(
        (l) => l, (_) => const UnexpectedFailure("Incorrect fold logic"));
    log.warning(
        "[GetFinancialOverviewUseCase] Failed to fetch $context: ${failure.message}");
    return Left(failure);
  }

  double _logAndDefault(Failure failure, String context, double defaultValue) {
    log.warning(
        "[GetFinancialOverviewUseCase] Failed to get $context: ${failure.message}. Defaulting to $defaultValue.");
    return defaultValue;
  }

  Future<List<BudgetWithStatus>> _getBudgetSummary() async {
    /* ... unchanged ... */
    List<BudgetWithStatus> budgetStatuses = [];
    Failure? budgetError;
    final budgetsResult = await budgetRepository.getBudgets();
    await budgetsResult.fold((failure) async => budgetError = failure,
        (budgets) async {
      const thrivingColor = Colors.green; // Consider moving to theme constants
      const nearingLimitColor = Colors.orange;
      const overLimitColor = Colors.red;
      for (final budget in budgets) {
        final (periodStart, periodEnd) = budget.getCurrentPeriodDates();
        final spentResult = await budgetRepository.calculateAmountSpent(
            budget: budget, periodStart: periodStart, periodEnd: periodEnd);
        spentResult.fold((f) {
          log.warning(
              "[GetFinancialOverviewUseCase] Failed calc for budget ${budget.id}: ${f.message}");
          budgetError ??= f;
        }, (spent) {
          budgetStatuses.add(BudgetWithStatus.calculate(
              budget: budget,
              amountSpent: spent,
              thrivingColor: thrivingColor,
              nearingLimitColor: nearingLimitColor,
              overLimitColor: overLimitColor));
        });
        if (budgetError != null && !budgetError!.message.contains("Validation"))
          break;
      }
    });
    if (budgetError != null) {
      log.warning(
          "[GetFinancialOverviewUseCase] Error during budget status calculation: ${budgetError!.message}");
    }
    budgetStatuses.sort((a, b) => b.percentageUsed.compareTo(a.percentageUsed));
    return budgetStatuses.take(3).toList();
  }

  Future<List<Goal>> _getGoalSummary() async {
    /* ... unchanged ... */
    Failure? goalError;
    List<Goal> goalSummary = [];
    final goalsResult = await goalRepository.getGoals(includeArchived: false);
    goalsResult.fold((failure) => goalError = failure, (activeGoals) {
      activeGoals
          .sort((a, b) => b.percentageComplete.compareTo(a.percentageComplete));
      goalSummary = activeGoals.take(3).toList();
    });
    if (goalError != null) {
      log.warning(
          "[GetFinancialOverviewUseCase] Error fetching goals: ${goalError!.message}");
    }
    return goalSummary;
  }

  // --- ADDED Helper to fetch recent spending data ---
  Future<List<TimeSeriesDataPoint>> _getRecentSpendingData() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 6)); // Last 7 days
    final reportResult = await reportRepository.getSpendingOverTime(
      startDate: startDate,
      endDate: endDate,
      granularity: TimeSeriesGranularity.daily, // Get daily data
      // No account/category filters for overview sparkline
    );
    return reportResult.fold(
      (l) {
        log.warning(
            "[GetFinancialOverviewUseCase] Failed to get sparkline data: ${l.message}");
        return []; // Return empty list on failure
      },
      (data) => data.spendingData,
    );
  }
  // --- END ADDED Helper ---
}

class GetFinancialOverviewParams extends Equatable {
  final DateTime? startDate; // Period for Income/Expense/NetFlow totals
  final DateTime? endDate;

  const GetFinancialOverviewParams({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
