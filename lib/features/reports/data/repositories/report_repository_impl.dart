// lib/features/reports/data/repositories/report_repository_impl.dart
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart'; // Added
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart'; // Added for types
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart'; // Added
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart'; // Added
import 'package:expense_tracker/features/income/data/models/income_model.dart'; // Added for types
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/main.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart'; // Added
import 'package:flutter/material.dart'; // Added for Color

class ReportRepositoryImpl implements ReportRepository {
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;
  final CategoryRepository categoryRepository;
  final AssetAccountRepository accountRepository;
  final BudgetRepository budgetRepository; // Added
  final GoalRepository goalRepository; // Added
  final GoalContributionRepository goalContributionRepository; // Added

  ReportRepositoryImpl({
    required this.expenseRepository,
    required this.incomeRepository,
    required this.categoryRepository,
    required this.accountRepository,
    required this.budgetRepository, // Added
    required this.goalRepository, // Added
    required this.goalContributionRepository, // Added
  });

  // --- Helper to get previous period dates ---
  ({DateTime start, DateTime end}) _getPreviousPeriod(
      DateTime currentStart, DateTime currentEnd) {
    final duration = currentEnd.difference(currentStart);
    final prevEnd = currentStart.subtract(
        const Duration(microseconds: 1)); // Go back 1 microsecond from start
    final prevStart = prevEnd.subtract(duration);
    return (start: prevStart, end: prevEnd);
  }

  @override
  Future<Either<Failure, SpendingCategoryReportData>> getSpendingByCategory({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? accountIds,
    bool compareToPrevious = false, // Added flag
  }) async {
    log.info(
        "[ReportRepo] getSpendingByCategory: Start=$startDate, End=$endDate, Accounts=${accountIds?.length}, Compare=$compareToPrevious");
    try {
      final currentDataEither =
          await _calculateSpendingByCategory(startDate, endDate, accountIds);
      if (currentDataEither.isLeft()) return currentDataEither;
      final currentData = currentDataEither
          .getOrElse(() => throw Exception("Should not happen"));

      SpendingCategoryReportData? previousData;
      if (compareToPrevious) {
        final prevDates = _getPreviousPeriod(startDate, endDate);
        final previousDataEither = await _calculateSpendingByCategory(
            prevDates.start, prevDates.end, accountIds);
        if (previousDataEither.isRight()) {
          previousData = previousDataEither
              .getOrElse(() => throw Exception("Should not happen"));
          log.fine("[ReportRepo] Fetched previous period category spending.");
        } else {
          log.warning(
              "[ReportRepo] Failed to fetch previous period category spending. Comparison unavailable.");
        }
      }

      return Right(SpendingCategoryReportData(
        totalSpending: currentData.totalSpending,
        spendingByCategory: currentData.spendingByCategory,
        previousTotalSpending: previousData?.totalSpending,
        previousSpendingByCategory: previousData?.spendingByCategory,
      ));
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getSpendingByCategory$e$s");
      return Left(
          UnexpectedFailure("Failed to generate category spending report: $e"));
    }
  }

  // --- Extracted helper for calculation ---
  Future<Either<Failure, SpendingCategoryReportData>>
      _calculateSpendingByCategory(DateTime startDate, DateTime endDate,
          List<String>? accountIds) async {
    // 1. Fetch relevant expense models
    final expenseResult = await expenseRepository.getExpenses(
        startDate: startDate,
        endDate: endDate,
        accountId: accountIds
            ?.join(',') // Pass multiple if repo supports, else filter here
        );
    if (expenseResult.isLeft()) {
      return expenseResult.fold((l) => Left(l),
          (_) => const Left(CacheFailure("Failed to get expenses")));
    }
    final expenseModels = expenseResult.getOrElse(() => []);

    final filteredExpenses = (accountIds == null || accountIds.isEmpty)
        ? expenseModels
        : expenseModels.where((e) => accountIds.contains(e.accountId)).toList();

    if (filteredExpenses.isEmpty) {
      return const Right(
          SpendingCategoryReportData(totalSpending: 0, spendingByCategory: []));
    }

    // 2. Fetch categories
    final categoryResult = await categoryRepository.getAllCategories();
    if (categoryResult.isLeft()) {
      return categoryResult.fold((l) => Left(l),
          (_) => const Left(CacheFailure("Failed to get categories")));
    }
    final categoryMap = {
      for (var cat in categoryResult.getOrElse(() => [])) cat.id: cat
    };
    final uncategorized = Category.uncategorized;

    // 3. Aggregate
    final Map<String, double> spendingMap = {};
    double totalSpending = 0;
    for (final expense in filteredExpenses) {
      final categoryId = expense.categoryId ?? uncategorized.id;
      spendingMap.update(categoryId, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
      totalSpending += expense.amount;
    }

    // 4. Create Data list
    final List<CategorySpendingData> reportData =
        spendingMap.entries.map((entry) {
      final categoryId = entry.key;
      final amount = entry.value;
      final category =
          categoryMap[categoryId] ?? uncategorized.copyWith(id: categoryId);
      final percentage = totalSpending > 0 ? (amount / totalSpending) : 0.0;
      return CategorySpendingData(
        categoryId: categoryId,
        categoryName: category.name,
        categoryColor: category.displayColor,
        totalAmount: amount,
        percentage: percentage,
      );
    }).toList();

    // 5. Sort
    reportData.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return Right(SpendingCategoryReportData(
      totalSpending: totalSpending,
      spendingByCategory: reportData,
    ));
  }

  @override
  Future<Either<Failure, SpendingTimeReportData>> getSpendingOverTime({
    required DateTime startDate,
    required DateTime endDate,
    required TimeSeriesGranularity granularity,
    List<String>? accountIds,
    List<String>? categoryIds,
    bool compareToPrevious = false, // Added flag
  }) async {
    log.info(
        "[ReportRepo] getSpendingOverTime: Granularity=$granularity, Start=$startDate, End=$endDate, Accounts=${accountIds?.length}, Cats=${categoryIds?.length}, Compare=$compareToPrevious");
    try {
      final currentDataEither = await _calculateSpendingOverTime(
          startDate, endDate, granularity, accountIds, categoryIds);
      if (currentDataEither.isLeft()) return currentDataEither;
      final currentData = currentDataEither
          .getOrElse(() => throw Exception("Should not happen"));

      SpendingTimeReportData? previousData;
      if (compareToPrevious) {
        final prevDates = _getPreviousPeriod(startDate, endDate);
        final previousDataEither = await _calculateSpendingOverTime(
            prevDates.start,
            prevDates.end,
            granularity,
            accountIds,
            categoryIds);
        if (previousDataEither.isRight()) {
          previousData = previousDataEither
              .getOrElse(() => throw Exception("Should not happen"));
          log.fine("[ReportRepo] Fetched previous period time spending.");
        } else {
          log.warning(
              "[ReportRepo] Failed to fetch previous period time spending. Comparison unavailable.");
        }
      }

      return Right(SpendingTimeReportData(
        spendingData: currentData.spendingData,
        granularity: currentData.granularity,
        previousSpendingData: previousData?.spendingData,
      ));
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getSpendingOverTime$e$s");
      return Left(UnexpectedFailure(
          "Failed to generate spending over time report: $e"));
    }
  }

  // --- Extracted helper for calculation ---
  Future<Either<Failure, SpendingTimeReportData>> _calculateSpendingOverTime(
      DateTime startDate,
      DateTime endDate,
      TimeSeriesGranularity granularity,
      List<String>? accountIds,
      List<String>? categoryIds) async {
    final expenseResult = await expenseRepository.getExpenses(
      startDate: startDate,
      endDate: endDate,
      accountId: accountIds?.join(','),
      category: categoryIds?.join(','),
    );
    if (expenseResult.isLeft())
      return expenseResult.fold(
          (l) => Left(l), (_) => const Left(CacheFailure("Failed")));
    final expenseModels = expenseResult.getOrElse(() => []);

    final filteredExpenses = expenseModels.where((e) {
      bool accountMatch = accountIds == null ||
          accountIds.isEmpty ||
          accountIds.contains(e.accountId);
      bool categoryMatch = categoryIds == null ||
          categoryIds.isEmpty ||
          categoryIds.contains(e.categoryId);
      return accountMatch && categoryMatch;
    }).toList();

    if (filteredExpenses.isEmpty) {
      return Right(
          SpendingTimeReportData(spendingData: [], granularity: granularity));
    }

    final Map<DateTime, double> aggregatedData = {};
    for (final expense in filteredExpenses) {
      DateTime periodKey;
      switch (granularity) {
        case TimeSeriesGranularity.daily:
          periodKey =
              DateTime(expense.date.year, expense.date.month, expense.date.day);
          break;
        case TimeSeriesGranularity.weekly:
          int daysToSubtract = expense.date.weekday - 1;
          periodKey = DateTime(expense.date.year, expense.date.month,
              expense.date.day - daysToSubtract);
          break;
        case TimeSeriesGranularity.monthly:
          periodKey = DateTime(expense.date.year, expense.date.month, 1);
          break;
      }
      aggregatedData.update(periodKey, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    final List<TimeSeriesDataPoint> reportData = aggregatedData.entries
        .map((entry) =>
            TimeSeriesDataPoint(date: entry.key, amount: entry.value))
        .toList();
    reportData.sort((a, b) => a.date.compareTo(b.date));

    return Right(SpendingTimeReportData(
        spendingData: reportData, granularity: granularity));
  }

  @override
  Future<Either<Failure, IncomeExpenseReportData>> getIncomeVsExpense({
    required DateTime startDate,
    required DateTime endDate,
    required IncomeExpensePeriodType periodType,
    List<String>? accountIds,
    bool compareToPrevious = false, // Added flag
  }) async {
    log.info(
        "[ReportRepo] getIncomeVsExpense: Period=$periodType, Start=$startDate, End=$endDate, Accounts=${accountIds?.length}, Compare=$compareToPrevious");
    try {
      final currentDataEither = await _calculateIncomeVsExpense(
          startDate, endDate, periodType, accountIds);
      if (currentDataEither.isLeft()) return currentDataEither;
      final currentData = currentDataEither
          .getOrElse(() => throw Exception("Should not happen"));

      IncomeExpenseReportData? previousData;
      if (compareToPrevious) {
        final prevDates = _getPreviousPeriod(startDate, endDate);
        final previousDataEither = await _calculateIncomeVsExpense(
            prevDates.start, prevDates.end, periodType, accountIds);
        if (previousDataEither.isRight()) {
          previousData = previousDataEither
              .getOrElse(() => throw Exception("Should not happen"));
          log.fine("[ReportRepo] Fetched previous period income/expense data.");
        } else {
          log.warning(
              "[ReportRepo] Failed to fetch previous period income/expense data. Comparison unavailable.");
        }
      }

      return Right(IncomeExpenseReportData(
        periodData: currentData.periodData,
        periodType: currentData.periodType,
        previousPeriodData: previousData?.periodData,
      ));
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getIncomeVsExpense$e$s");
      return Left(
          UnexpectedFailure("Failed to generate income vs expense report: $e"));
    }
  }

  // --- Extracted helper for calculation ---
  Future<Either<Failure, IncomeExpenseReportData>> _calculateIncomeVsExpense(
      DateTime startDate,
      DateTime endDate,
      IncomeExpensePeriodType periodType,
      List<String>? accountIds) async {
    final expenseResult = await expenseRepository.getExpenses(
        startDate: startDate,
        endDate: endDate,
        accountId: accountIds?.join(','));
    final incomeResult = await incomeRepository.getIncomes(
        startDate: startDate,
        endDate: endDate,
        accountId: accountIds?.join(','));

    if (expenseResult.isLeft())
      return expenseResult.fold((l) => Left(l),
          (_) => const Left(CacheFailure("Failed to get expenses")));
    if (incomeResult.isLeft())
      return incomeResult.fold((l) => Left(l),
          (_) => const Left(CacheFailure("Failed to get income")));

    final expenses = expenseResult.getOrElse(() => []);
    final incomes = incomeResult.getOrElse(() => []);

    final filteredExpenses = (accountIds == null || accountIds.isEmpty)
        ? expenses
        : expenses.where((e) => accountIds.contains(e.accountId)).toList();
    final filteredIncomes = (accountIds == null || accountIds.isEmpty)
        ? incomes
        : incomes.where((i) => accountIds.contains(i.accountId)).toList();

    final Map<DateTime, ({double income, double expense})> aggregatedData = {};

    void aggregate(dynamic transaction, bool isIncome) {
      final date = transaction.date;
      final periodKeyDate = periodType == IncomeExpensePeriodType.monthly
          ? DateTime(date.year, date.month, 1)
          : DateTime(date.year, 1, 1);
      final amount = transaction.amount;
      final current =
          aggregatedData[periodKeyDate] ?? (income: 0.0, expense: 0.0);
      aggregatedData[periodKeyDate] = isIncome
          ? (income: current.income + amount, expense: current.expense)
          : (income: current.income, expense: current.expense + amount);
    }

    for (final income in filteredIncomes) {
      aggregate(income, true);
    }
    for (final expense in filteredExpenses) {
      aggregate(expense, false);
    }

    final List<IncomeExpensePeriodData> reportData = aggregatedData.entries
        .map((entry) => IncomeExpensePeriodData(
            periodStart: entry.key,
            totalIncome: entry.value.income,
            totalExpense: entry.value.expense))
        .toList();
    reportData.sort((a, b) => a.periodStart.compareTo(b.periodStart));

    return Right(IncomeExpenseReportData(
        periodData: reportData, periodType: periodType));
  }

  // --- ADDED Budget Performance Implementation ---
  @override
  Future<Either<Failure, BudgetPerformanceReportData>> getBudgetPerformance({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? budgetIds,
    bool compareToPrevious = false,
  }) async {
    log.info(
        "[ReportRepo] getBudgetPerformance: Start=$startDate, End=$endDate, Budgets=${budgetIds?.length}, Compare=$compareToPrevious");
    try {
      // Fetch current period performance
      final currentPerformanceEither =
          await _calculateBudgetPerformance(startDate, endDate, budgetIds);
      if (currentPerformanceEither.isLeft()) return currentPerformanceEither;
      final currentPerformance = currentPerformanceEither
          .getOrElse(() => throw Exception("Should not happen"));

      // Fetch previous period performance if requested
      List<BudgetPerformanceData>? previousPerformance;
      double?
          previousTotalVariance; // Optional: Calculate overall variance difference
      if (compareToPrevious) {
        final prevDates = _getPreviousPeriod(startDate, endDate);
        final previousPerformanceEither = await _calculateBudgetPerformance(
            prevDates.start, prevDates.end, budgetIds);
        if (previousPerformanceEither.isRight()) {
          previousPerformance = previousPerformanceEither
              .getOrElse(() => throw Exception("Should not happen"))
              .performanceData;
          // Optional: Calculate overall variance change if needed
          // final currentTotalVariance = currentPerformance.performanceData.fold(0.0, (sum, item) => sum + item.varianceAmount);
          // previousTotalVariance = previousPerformance.fold(0.0, (sum, item) => sum + item.varianceAmount);
          log.fine("[ReportRepo] Fetched previous period budget performance.");
        } else {
          log.warning(
              "[ReportRepo] Failed to fetch previous period budget performance. Comparison unavailable.");
        }
      }

      return Right(BudgetPerformanceReportData(
        performanceData: currentPerformance.performanceData,
        previousPerformanceData: previousPerformance,
        previousTotalVariance: previousTotalVariance,
      ));
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getBudgetPerformance$e$s");
      return Left(UnexpectedFailure(
          "Failed to generate budget performance report: $e"));
    }
  }

  // --- Extracted Budget Performance Calculation ---
  Future<Either<Failure, BudgetPerformanceReportData>>
      _calculateBudgetPerformance(
          DateTime startDate, DateTime endDate, List<String>? budgetIds) async {
    final budgetsResult = await budgetRepository.getBudgets();
    if (budgetsResult.isLeft())
      return budgetsResult.fold(
          (l) => Left(l), (_) => const Left(CacheFailure("Failed")));
    final allBudgets = budgetsResult.getOrElse(() => []);

    // Filter by provided budget IDs if necessary
    final relevantBudgets = (budgetIds == null || budgetIds.isEmpty)
        ? allBudgets
        : allBudgets.where((b) => budgetIds.contains(b.id)).toList();

    if (relevantBudgets.isEmpty) {
      return const Right(BudgetPerformanceReportData(performanceData: []));
    }

    // Define colors (should ideally come from theme)
    const thrivingColor = Colors.green;
    const nearingLimitColor = Colors.orange;
    const overLimitColor = Colors.red;

    List<BudgetPerformanceData> performanceList = [];
    Failure? calcFailure;

    for (final budget in relevantBudgets) {
      // Use the budget's own period if it's one-time and falls within the report range,
      // otherwise use the report's range for recurring monthly.
      final (effStart, effEnd) = (budget.period == BudgetPeriodType.oneTime &&
              budget.startDate != null &&
              budget.endDate != null)
          ? (budget.startDate!, budget.endDate!) // Use budget's specific dates
          : (startDate, endDate); // Use report range for recurring

      final spentResult = await budgetRepository.calculateAmountSpent(
          budget: budget, periodStart: effStart, periodEnd: effEnd);

      spentResult.fold((f) {
        calcFailure ??= f;
        log.warning("Calc error for budget ${budget.id}: ${f.message}");
      }, (spent) {
        final target = budget.targetAmount;
        final variance = target - spent;
        final variancePercent = target > 0
            ? (variance / target) * 100
            : (spent > 0 ? -double.infinity : 0.0);
        final statusResult = BudgetWithStatus.calculate(
            budget: budget,
            amountSpent: spent,
            thrivingColor: thrivingColor,
            nearingLimitColor: nearingLimitColor,
            overLimitColor: overLimitColor);

        performanceList.add(BudgetPerformanceData(
          budget: budget,
          actualSpending: spent,
          varianceAmount: variance,
          variancePercent: variancePercent,
          health: statusResult.health,
          statusColor: statusResult.statusColor,
        ));
      });
      if (calcFailure != null) break; // Stop if a critical error occurred
    }

    if (calcFailure != null) {
      return Left(calcFailure!);
    }

    performanceList.sort((a, b) =>
        a.budget.name.compareTo(b.budget.name)); // Sort alphabetically
    return Right(BudgetPerformanceReportData(performanceData: performanceList));
  }

  // --- ADDED Goal Progress Implementation ---
  @override
  Future<Either<Failure, GoalProgressReportData>> getGoalProgress({
    List<String>? goalIds,
    bool calculateComparisonRate = false, // Placeholder for future comparison
  }) async {
    log.info(
        "[ReportRepo] getGoalProgress: Goals=${goalIds?.length ?? 'All Active'}, CompareRate=$calculateComparisonRate");
    try {
      // 1. Fetch relevant goals (default to active)
      final goalsResult = await goalRepository.getGoals(includeArchived: false);
      if (goalsResult.isLeft())
        return goalsResult.fold(
            (l) => Left(l), (_) => const Left(CacheFailure("Failed")));
      final allActiveGoals = goalsResult.getOrElse(() => []);

      final relevantGoals = (goalIds == null || goalIds.isEmpty)
          ? allActiveGoals
          : allActiveGoals.where((g) => goalIds.contains(g.id)).toList();

      if (relevantGoals.isEmpty) {
        return const Right(GoalProgressReportData(progressData: []));
      }

      // 2. Fetch contributions for each goal
      List<GoalProgressData> progressList = [];
      Failure? contribFailure;

      for (final goal in relevantGoals) {
        final contribResult =
            await goalContributionRepository.getContributionsForGoal(goal.id);
        contribResult.fold((f) {
          contribFailure ??= f;
          log.warning("Contrib fetch error for goal ${goal.id}: ${f.message}");
        }, (contributions) {
          // TODO: Calculate pacing metrics if needed (neededPerMonth, etc.)
          progressList.add(GoalProgressData(
            goal: goal,
            contributions: contributions, // Include full history for now
            // neededPerMonth: _calculatePacing(goal), // Example
          ));
        });
        if (contribFailure != null) break; // Stop if critical error
      }

      if (contribFailure != null) {
        return Left(contribFailure!);
      }

      // 3. Sort goals (e.g., by closest target date, highest percentage)
      progressList.sort((a, b) => a.goal.percentageComplete.compareTo(
          b.goal.percentageComplete)); // Example: sort by least complete first

      log.info(
          "[ReportRepo] Goal progress report generated. Goals: ${progressList.length}");
      // TODO: Implement comparison rate calculation if calculateComparisonRate is true
      return Right(GoalProgressReportData(progressData: progressList));
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getGoalProgress$e$s");
      return Left(
          UnexpectedFailure("Failed to generate goal progress report: $e"));
    }
  }
}
