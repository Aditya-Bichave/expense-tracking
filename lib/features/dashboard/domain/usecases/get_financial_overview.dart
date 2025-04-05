import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';

import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart'; // ADDED
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart'; // ADDED
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart'; // ADDED

import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart'; // Import logger

class GetFinancialOverviewUseCase
    implements UseCase<FinancialOverview, GetFinancialOverviewParams> {
  final AssetAccountRepository accountRepository;
  final IncomeRepository incomeRepository;
  final ExpenseRepository expenseRepository;
  final BudgetRepository budgetRepository; // ADDED
  final GoalRepository goalRepository; // ADDED

  GetFinancialOverviewUseCase({
    required this.accountRepository,
    required this.incomeRepository,
    required this.expenseRepository,
    required this.budgetRepository, // ADDED
    required this.goalRepository, // ADDED
  });

  @override
  Future<Either<Failure, FinancialOverview>> call(
      GetFinancialOverviewParams params) async {
    log.info(
        "Executing GetFinancialOverviewUseCase. Start: ${params.startDate}, End: ${params.endDate}");
    try {
      // 1. Get all accounts (with calculated balances)
      log.info("[GetFinancialOverviewUseCase] Fetching accounts...");
      final accountsEither = await accountRepository.getAssetAccounts();

      if (accountsEither.isLeft()) {
        log.warning("[GetFinancialOverviewUseCase] Failed to fetch accounts.");
        // Propagate the failure directly
        return accountsEither.fold((l) => Left(l),
            (_) => const Left(CacheFailure("Failed to retrieve accounts.")));
      }
      final accounts = accountsEither.getOrElse(() => []); // Safe extraction
      log.info(
          "[GetFinancialOverviewUseCase] Fetched ${accounts.length} accounts.");

      // 2. Calculate overall balance
      final double overallBalance =
          accounts.fold(0.0, (sum, acc) => sum + acc.currentBalance);
      log.info(
          "[GetFinancialOverviewUseCase] Calculated overall balance: $overallBalance");

      // 3. Create the map for the pie chart <AccountName, Balance>
      // Filter out non-positive balances here if the chart widget doesn't handle it
      final Map<String, double> accountBalancesMap = {
        for (var acc in accounts) acc.name: acc.currentBalance
      };
      log.info(
          "[GetFinancialOverviewUseCase] Created account balances map (${accountBalancesMap.length} entries).");

      // 4. Get total income/expenses for the period (using date filters if provided)
      log.info(
          "[GetFinancialOverviewUseCase] Fetching total income/expenses...");
      final incomeResult = await incomeRepository.getTotalIncomeForAccount(
        '', // Pass empty accountId to get all
        startDate: params.startDate,
        endDate: params.endDate,
      );
      final expenseResult = await expenseRepository.getTotalExpensesForAccount(
        '', // Pass empty accountId to get all
        startDate: params.startDate,
        endDate: params.endDate,
      );

      // Handle potential failures for income/expense totals, default to 0
      final totalIncome = incomeResult.fold((l) {
        log.warning(
            "[GetFinancialOverviewUseCase] Failed to get total income: ${l.message}. Defaulting to 0.");
        return 0.0;
      }, (r) => r);
      final totalExpenses = expenseResult.fold((l) {
        log.warning(
            "[GetFinancialOverviewUseCase] Failed to get total expenses: ${l.message}. Defaulting to 0.");
        return 0.0;
      }, (r) => r);
      final netFlow = totalIncome - totalExpenses;
      log.info(
          "[GetFinancialOverviewUseCase] Income: $totalIncome, Expenses: $totalExpenses, Net Flow: $netFlow");

      // --- Fetch Budget Statuses ---
      log.info(
          "[GetFinancialOverviewUseCase] Fetching budgets and calculating statuses...");
      List<BudgetWithStatus> budgetStatuses = [];
      Failure? budgetError;
      final budgetsResult = await budgetRepository.getBudgets();
      await budgetsResult
          .fold((failure) async => budgetError = failure, // Store error
              (budgets) async {
        // Define colors needed for status calculation
        const thrivingColor = Colors.green;
        const nearingLimitColor = Colors.orange;
        const overLimitColor = Colors.red;
        List<Future<void>> calcFutures = [];

        for (final budget in budgets) {
          // Calculate status for each budget
          final (periodStart, periodEnd) = budget.getCurrentPeriodDates();
          final spentResult = await budgetRepository.calculateAmountSpent(
              budget: budget, periodStart: periodStart, periodEnd: periodEnd);
          spentResult.fold((f) {
            log.warning(
                "[GetFinancialOverviewUseCase] Failed calc for budget ${budget.id}: ${f.message}");
            budgetError ??= f; // Store first error
          }, (spent) {
            budgetStatuses.add(BudgetWithStatus.calculate(
                budget: budget,
                amountSpent: spent,
                thrivingColor: thrivingColor,
                nearingLimitColor: nearingLimitColor,
                overLimitColor: overLimitColor));
          });
          // If critical error, maybe break early?
          if (budgetError != null &&
              !budgetError!.message.contains("Validation")) break;
        }
      });
      if (budgetError != null) {
        log.warning(
            "[GetFinancialOverviewUseCase] Error occurred during budget status calculation: ${budgetError!.message}");
        // Proceed with potentially incomplete budget list or return error? Proceeding for now.
      }
      // Sort budgets for summary (e.g., most spent % first)
      budgetStatuses
          .sort((a, b) => b.percentageUsed.compareTo(a.percentageUsed));
      final budgetSummary = budgetStatuses.take(3).toList(); // Take top 3
      log.info(
          "[GetFinancialOverviewUseCase] Prepared budget summary with ${budgetSummary.length} items.");
      // --- End Fetch Budget ---

      // --- Fetch Goal Summary ---
      log.info(
          "[GetFinancialOverviewUseCase] Fetching active goals summary...");
      Failure? goalError;
      List<Goal> goalSummary = [];
      final goalsResult = await goalRepository.getGoals(
          includeArchived: false); // Fetch active goals
      goalsResult.fold((failure) => goalError = failure, (activeGoals) {
        // Sort by percentage complete descending
        activeGoals.sort(
            (a, b) => b.percentageComplete.compareTo(a.percentageComplete));
        goalSummary = activeGoals.take(3).toList(); // Take top 3
      });
      if (goalError != null) {
        log.warning(
            "[GetFinancialOverviewUseCase] Error fetching goals: ${goalError!.message}");
        // Proceed with empty goal summary
      }
      log.info(
          "[GetFinancialOverviewUseCase] Prepared goal summary with ${goalSummary.length} items.");
      // --- End Fetch Goal ---

      // 5. Construct the overview object
      final overview = FinancialOverview(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        netFlow: netFlow,
        overallBalance: overallBalance,
        accounts: accounts,
        accountBalances: accountBalancesMap,
        activeBudgetsSummary: budgetSummary, // ADDED
        activeGoalsSummary: goalSummary, // ADDED
      );
      log.info(
          "[GetFinancialOverviewUseCase] Successfully created FinancialOverview. Returning Right.");
      return Right(overview);
    } catch (e, s) {
      log.severe("[GetFinancialOverviewUseCase] Unexpected error" +
          e.toString() +
          s.toString());
      return Left(UnexpectedFailure(
          'Failed to generate financial overview: ${e.toString()}'));
    }
  }
}

class GetFinancialOverviewParams extends Equatable {
  final DateTime? startDate; // Optional filter for income/expense totals
  final DateTime? endDate;

  const GetFinancialOverviewParams({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
