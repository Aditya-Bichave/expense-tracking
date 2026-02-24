import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart'; // Added
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/main.dart'; // Logger
import 'package:flutter/material.dart'; // For color handling

class ReportRepositoryImpl implements ReportRepository {
  final IncomeRepository incomeRepository;
  final ExpenseRepository expenseRepository;
  final CategoryRepository categoryRepository;
  final BudgetRepository budgetRepository;
  final GoalRepository goalRepository;
  final GoalContributionRepository goalContributionRepository;

  ReportRepositoryImpl({
    required this.incomeRepository,
    required this.expenseRepository,
    required this.categoryRepository,
    required this.budgetRepository,
    required this.goalRepository,
    required this.goalContributionRepository,
  });

  @override
  Future<Either<Failure, SpendingCategoryReportData>> getSpendingByCategory({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? accountIds,
    List<String>? categoryIds, // Added
    TransactionType? transactionType,
    bool compareToPrevious = false,
  }) async {
    log.info(
      "[ReportRepo] getSpendingByCategory: Start=$startDate, End=$endDate, Compare=$compareToPrevious",
    );
    try {
      final currentData = await _calculateSpendingByCategory(
        startDate,
        endDate,
        accountIds,
        categoryIds, // Pass categoryIds
      );
      if (currentData.isLeft()) {
        return currentData.fold(
          (l) => Left(l),
          (r) => throw UnimplementedError(),
        );
      }
      final currentSpending = currentData.getOrElse(() => []);

      List<CategorySpendingData>? previousSpending;
      if (compareToPrevious) {
        final duration = endDate.difference(startDate);
        final previousEndDate = startDate.subtract(const Duration(seconds: 1));
        final previousStartDate = previousEndDate.subtract(duration);
        log.info(
          "[ReportRepo] Calculating previous spending: Start=$previousStartDate, End=$previousEndDate",
        );
        final prevData = await _calculateSpendingByCategory(
          previousStartDate,
          previousEndDate,
          accountIds,
          categoryIds, // Pass categoryIds
        );
        previousSpending = prevData.getOrElse(() => []);
      }

      final reportData = SpendingCategoryReportData(
        totalSpending: ComparisonValue(
          currentValue: currentSpending.fold<double>(
            0.0,
            (sum, item) => sum + item.currentTotalAmount,
          ),
          previousValue: previousSpending?.fold<double>(
            0.0,
            (sum, item) => sum + item.currentTotalAmount,
          ),
        ),
        spendingByCategory: currentSpending,
      );
      return Right(reportData);
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getSpendingByCategory$e$s");
      return Left(
        UnexpectedFailure(
          "Failed to generate spending by category report: $e",
        ),
      );
    }
  }

  Future<Either<Failure, List<CategorySpendingData>>>
  _calculateSpendingByCategory(
    DateTime start,
    DateTime end,
    List<String>? accountIds,
    List<String>? categoryIds,
  ) async {
    // Parallel fetch: expenses and categories (for names/colors)
    final expensesFuture = expenseRepository.getExpenses(
      startDate: start,
      endDate: end,
      // accountIds not supported by repository, filtering in memory
      categoryId: categoryIds?.isNotEmpty == true ? categoryIds!.first : null,
    );
    final categoriesFuture = categoryRepository.getAllCategories();

    final results = await Future.wait([expensesFuture, categoriesFuture]);
    final expensesResult = results[0]
        as Either<Failure, List<dynamic>>; // dynamic because repo returns generic
    final categoriesResult = results[1] as Either<Failure, List<Category>>;

    if (categoriesResult.isLeft()) {
      return Left(
        categoriesResult.fold(
          (l) => l,
          (_) => const UnexpectedFailure("Fold error"),
        ),
      );
    }
    final allCategories = categoriesResult.getOrElse(() => []);
    final categoryMap = {for (var c in allCategories) c.id: c};

    return expensesResult.fold((failure) => Left(failure), (rawExpenses) {
      // Cast rawExpenses to List<ExpenseModel> or assume dynamic access works if typed correctly
      // ExpenseRepository returns List<ExpenseModel>
      final expenses = rawExpenses;

      final filteredExpenses = expenses.where((e) {
        // e is ExpenseModel
        if (accountIds != null &&
            accountIds.isNotEmpty &&
            !accountIds.contains(e.accountId)) {
          return false;
        }
        return true;
      }).toList();

      final Map<String, double> categoryTotals = {};
      final Map<String, Color> categoryColors = {};
      final Map<String, String> categoryNames = {};

      for (final expense in filteredExpenses) {
        // expense is ExpenseModel
        final categoryId = expense.categoryId ?? 'uncategorized';
        final category = categoryMap[categoryId];
        final categoryName = category?.name ?? 'Uncategorized';
        final categoryColor = category?.displayColor ?? Colors.grey;

        categoryTotals.update(
          categoryId,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
        categoryColors.putIfAbsent(categoryId, () => categoryColor);
        categoryNames.putIfAbsent(categoryId, () => categoryName);
      }

      final double totalSpending = categoryTotals.values.fold(
        0.0,
        (sum, val) => sum + val,
      );
      final List<CategorySpendingData> data = categoryTotals.entries
          .map<CategorySpendingData>((entry) {
            // Typed map
            final categoryId = entry.key;
            final amount = entry.value;
            final percentage =
                totalSpending > 0 ? (amount / totalSpending) : 0.0;
            return CategorySpendingData(
              categoryId: categoryId,
              categoryName: categoryNames[categoryId]!,
              categoryColor: categoryColors[categoryId]!,
              totalAmount: ComparisonValue(
                currentValue: amount,
              ), // Updated to ComparisonValue
              percentage: percentage,
            );
          })
          .toList();

      data.sort(
        (a, b) => b.currentTotalAmount.compareTo(a.currentTotalAmount),
      );
      return Right(data);
    });
  }

  @override
  Future<Either<Failure, SpendingTimeReportData>> getSpendingOverTime({
    required DateTime startDate,
    required DateTime endDate,
    required TimeSeriesGranularity granularity,
    List<String>? accountIds,
    List<String>? categoryIds,
    TransactionType? transactionType,
    bool compareToPrevious = false,
  }) async {
    final effectiveType = transactionType ?? TransactionType.expense;
    log.info(
      "[ReportRepo] getSpendingOverTime: Start=$startDate, End=$endDate, Granularity=$granularity, Compare=$compareToPrevious, Type=${effectiveType.name}",
    );

    try {
      final currentResult = await _calculateSpendingOverTime(
        startDate,
        endDate,
        granularity,
        accountIds,
        categoryIds,
        effectiveType,
      );
      if (currentResult.isLeft())
        return currentResult.fold((l) => Left(l), (r) => Right(r));

      final currentReport = currentResult.getOrElse(
        () => throw UnimplementedError(),
      );

      SpendingTimeReportData finalReport = currentReport;

      if (compareToPrevious) {
        final duration = endDate.difference(startDate);
        final previousEndDate = startDate.subtract(const Duration(seconds: 1));
        final previousStartDate = previousEndDate.subtract(duration);

        final prevResult = await _calculateSpendingOverTime(
          previousStartDate,
          previousEndDate,
          granularity,
          accountIds,
          categoryIds,
          effectiveType,
        );

        if (prevResult.isRight()) {
          final prevReport = prevResult.getOrElse(
            () => throw UnimplementedError(),
          );

          final List<TimeSeriesDataPoint> mergedPoints = [];
          final int count = currentReport.spendingData.length;
          final int prevCount = prevReport.spendingData.length;

          for (int i = 0; i < count; i++) {
            final currentPoint = currentReport.spendingData[i];
            double? prevAmount;
            if (i < prevCount) {
              prevAmount = prevReport.spendingData[i].currentAmount;
            }
            mergedPoints.add(
              TimeSeriesDataPoint(
                date: currentPoint.date,
                amount: ComparisonValue(
                  currentValue: currentPoint.currentAmount,
                  previousValue: prevAmount,
                ),
              ),
            );
          }
          finalReport = SpendingTimeReportData(
            spendingData: mergedPoints,
            granularity: granularity,
          );
        }
      }

      return Right(finalReport);
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getSpendingOverTime$e$s");
      return Left(
        UnexpectedFailure("Failed to generate spending over time report: $e"),
      );
    }
  }

  Future<Either<Failure, SpendingTimeReportData>> _calculateSpendingOverTime(
    DateTime start,
    DateTime end,
    TimeSeriesGranularity granularity,
    List<String>? accountIds,
    List<String>? categoryIds,
    TransactionType type,
  ) async {
    List<dynamic> transactions = [];
    if (type == TransactionType.expense) {
      final result = await expenseRepository.getExpenses(
        startDate: start,
        endDate: end,
        categoryId: categoryIds?.isNotEmpty == true ? categoryIds!.first : null,
      );
      if (result.isLeft())
        return result.fold(
          (l) => Left(l),
          (_) => const Left(UnexpectedFailure("Fold error")),
        );
      var fetched = result.getOrElse(() => []);
      if (accountIds != null && accountIds.isNotEmpty) {
        fetched =
            fetched.where((e) => accountIds.contains(e.accountId)).toList();
      }
      transactions = fetched;
    } else {
      final result = await incomeRepository.getIncomes(
        startDate: start,
        endDate: end,
        categoryId: categoryIds?.isNotEmpty == true ? categoryIds!.first : null,
      );
      if (result.isLeft())
        return result.fold(
          (l) => Left(l),
          (_) => const Left(UnexpectedFailure("Fold error")),
        );
      var fetched = result.getOrElse(() => []);
      if (accountIds != null && accountIds.isNotEmpty) {
        fetched =
            fetched.where((i) => accountIds.contains(i.accountId)).toList();
      }
      transactions = fetched;
    }

    final Map<DateTime, double> aggregatedData = {};

    for (final txn in transactions) {
      DateTime date;
      double amount;
      // Handle both Models and Entities just in case, though usually Models now
      // ExpenseModel/IncomeModel have date/amount properties
      // Using dynamic access for simplicity as they share structure
      date = (txn as dynamic).date;
      amount = (txn as dynamic).amount;

      DateTime periodKey;
      switch (granularity) {
        case TimeSeriesGranularity.daily:
          periodKey = DateTime(date.year, date.month, date.day);
          break;
        case TimeSeriesGranularity.weekly:
          periodKey = date.subtract(Duration(days: date.weekday - 1));
          periodKey = DateTime(
            periodKey.year,
            periodKey.month,
            periodKey.day,
          );
          break;
        case TimeSeriesGranularity.monthly:
          periodKey = DateTime(date.year, date.month, 1);
          break;
      }

      aggregatedData.update(
        periodKey,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }

    DateTime current =
        granularity == TimeSeriesGranularity.monthly
            ? DateTime(start.year, start.month, 1)
            : (granularity == TimeSeriesGranularity.weekly
                ? start.subtract(Duration(days: start.weekday - 1)).copyWith(
                  hour: 0,
                  minute: 0,
                  second: 0,
                  millisecond: 0,
                  microsecond: 0,
                )
                : DateTime(start.year, start.month, start.day));

    final endCheck = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final List<TimeSeriesDataPoint> points = [];
    int iterations = 0;
    while (current.isBefore(endCheck) ||
        current.isAtSameMomentAs(endCheck) ||
        (current.year == endCheck.year &&
            current.month == endCheck.month &&
            current.day == endCheck.day)) {
      if (iterations++ > 1000) {
        log.warning(
          "[ReportRepo] Infinite loop detected in date generation. Breaking.",
        );
        break;
      }

      final amount = aggregatedData[current] ?? 0.0;
      points.add(
        TimeSeriesDataPoint(
          date: current,
          amount: ComparisonValue(currentValue: amount),
        ),
      );

      switch (granularity) {
        case TimeSeriesGranularity.daily:
          current = current.add(const Duration(days: 1));
          break;
        case TimeSeriesGranularity.weekly:
          current = current.add(const Duration(days: 7));
          break;
        case TimeSeriesGranularity.monthly:
          current = DateTime(current.year, current.month + 1, 1);
          break;
      }
    }

    return Right(
      SpendingTimeReportData(spendingData: points, granularity: granularity),
    );
  }

  @override
  Future<Either<Failure, IncomeExpenseReportData>> getIncomeVsExpense({
    required DateTime startDate,
    required DateTime endDate,
    required IncomeExpensePeriodType periodType, // Added
    List<String>? accountIds,
    bool compareToPrevious = false,
  }) async {
    log.info(
      "[ReportRepo] getIncomeVsExpense: Start=$startDate, End=$endDate, Compare=$compareToPrevious",
    );
    try {
      final incomeResult = await incomeRepository.getTotalIncomeForAccount(
        accountIds?.isNotEmpty == true ? accountIds!.first : '',
        startDate: startDate,
        endDate: endDate,
      );
      final expenseResult = await expenseRepository.getTotalExpensesForAccount(
        accountIds?.isNotEmpty == true ? accountIds!.first : '',
        startDate: startDate,
        endDate: endDate,
      );

      final currentIncome = incomeResult.getOrElse(() => 0.0);
      final currentExpense = expenseResult.getOrElse(() => 0.0);

      double? prevIncome;
      double? prevExpense;

      if (compareToPrevious) {
        final duration = endDate.difference(startDate);
        final previousEndDate = startDate.subtract(const Duration(seconds: 1));
        final previousStartDate = previousEndDate.subtract(duration);

        final prevIncomeRes = await incomeRepository.getTotalIncomeForAccount(
          accountIds?.isNotEmpty == true ? accountIds!.first : '',
          startDate: previousStartDate,
          endDate: previousEndDate,
        );
        final prevExpenseRes = await expenseRepository
            .getTotalExpensesForAccount(
              accountIds?.isNotEmpty == true ? accountIds!.first : '',
              startDate: previousStartDate,
              endDate: previousEndDate,
            );
        prevIncome = prevIncomeRes.getOrElse(() => 0.0);
        prevExpense = prevExpenseRes.getOrElse(() => 0.0);
      }

      // Create a single period summary since the original implementation only calculated total
      final periodData = IncomeExpensePeriodData(
        periodStart: startDate,
        totalIncome: ComparisonValue(
          currentValue: currentIncome,
          previousValue: prevIncome,
        ),
        totalExpense: ComparisonValue(
          currentValue: currentExpense,
          previousValue: prevExpense,
        ),
      );

      final reportData = IncomeExpenseReportData(
        periodData: [periodData], // Wrap in list
        periodType: periodType,
      );
      return Right(reportData);
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getIncomeVsExpense$e$s");
      return Left(
        UnexpectedFailure(
          "Failed to generate income vs expense report: $e",
        ),
      );
    }
  }

  @override
  Future<Either<Failure, BudgetPerformanceReportData>> getBudgetPerformance({
    required DateTime startDate, // Added
    required DateTime endDate,   // Added
    List<String>? budgetIds,
    List<String>? accountIds,    // Added
    bool compareToPrevious = false,
  }) async {
    log.info(
      "[ReportRepo] getBudgetPerformance: Budgets=${budgetIds?.length ?? 'All'}",
    );
    try {
      final budgetsResult = await budgetRepository.getBudgets();
      if (budgetsResult.isLeft())
        return budgetsResult.fold(
          (l) => Left(l),
          (_) => const Left(CacheFailure("Failed")),
        );
      final allBudgets = budgetsResult.getOrElse(() => []);

      final relevantBudgets = (budgetIds == null || budgetIds.isEmpty)
          ? allBudgets
          : allBudgets.where((b) => budgetIds.contains(b.id)).toList();

      if (relevantBudgets.isEmpty) {
        log.fine("[ReportRepo] No relevant budgets found.");
        return const Right(BudgetPerformanceReportData(performanceData: []));
      }

      final currentPerfData = await _calculateBudgetPerformance(
        relevantBudgets,
        isPreviousPeriod: false,
      );
      if (currentPerfData.isLeft())
        return currentPerfData.fold((l) => Left(l), (r) => throw Exception());
      final currentList = (currentPerfData as Right).value.performanceData;

      List<BudgetPerformanceData>? previousList;
      if (compareToPrevious) { // Use method argument
        final prevPerfData = await _calculateBudgetPerformance(
          relevantBudgets,
          isPreviousPeriod: true,
        );
        if (prevPerfData.isRight()) {
          previousList = (prevPerfData as Right).value.performanceData;
        }
      }

      final List<BudgetPerformanceData> mergedList = [];
      for (final currentItem in currentList) {
        BudgetPerformanceData? prevItem;
        if (previousList != null) {
          prevItem = previousList.firstWhereOrNull(
            (p) => p.budget.id == currentItem.budget.id,
          );
        }

        mergedList.add(
          currentItem.copyWith(
            actualSpending: ComparisonValue(
              currentValue: currentItem.currentActualSpending,
              previousValue: prevItem?.currentActualSpending,
            ),
            varianceAmount: ComparisonValue(
              currentValue: currentItem.currentVarianceAmount,
              previousValue: prevItem?.currentVarianceAmount,
            ),
            previousVariancePercent: prevItem?.currentVariancePercent,
          ),
        );
      }

      log.info(
        "[ReportRepo] Budget performance report generated. Count: ${mergedList.length}",
      );
      return Right(
        BudgetPerformanceReportData(
          performanceData: mergedList,
          previousPerformanceData: previousList,
        ),
      );
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getBudgetPerformance$e$s");
      return Left(
        UnexpectedFailure(
          "Failed to generate budget performance report: $e",
        ),
      );
    }
  }

  Future<Either<Failure, BudgetPerformanceReportData>>
  _calculateBudgetPerformance(
    List<Budget> budgets, {
    required bool isPreviousPeriod,
  }) async {
    final List<BudgetPerformanceData> performanceList = [];

    for (final budget in budgets) {
      var (start, end) = budget.getCurrentPeriodDates();
      if (isPreviousPeriod) {
        if (budget.period == BudgetPeriodType.recurringMonthly) { // Fixed enum usage
          final currentMonth = start;
          final prevMonth = DateTime(
            currentMonth.year,
            currentMonth.month - 1,
            1,
          );
          final dates = budget.getPeriodDatesFor(prevMonth);
          start = dates.$1; // Fixed tuple access
          end = dates.$2; // Fixed tuple access
        } else {
          final duration = end.difference(start);
          end = start.subtract(const Duration(seconds: 1));
          start = end.subtract(duration);
        }
      }

      final spentResult = await budgetRepository.calculateAmountSpent(
        budget: budget,
        periodStart: start,
        periodEnd: end,
      );
      final spent = spentResult.getOrElse(() => 0.0);
      final target = budget.targetAmount;
      final variance = target - spent;
      final variancePercent = target > 0
          ? (variance / target) * 100
          : (spent > 0 ? double.negativeInfinity : 0.0);

      final statusResult = BudgetWithStatus.calculate(
        budget: budget,
        amountSpent: spent,
      );

      performanceList.add(
        BudgetPerformanceData(
          budget: budget,
          actualSpending: ComparisonValue(currentValue: spent),
          varianceAmount: ComparisonValue(
            currentValue: variance,
          ),
          currentVariancePercent: variancePercent,
          health: statusResult.health,
          statusColor: _calculateStatusColor(statusResult.health),
        ),
      );
    }

    performanceList.sort(
      (a, b) =>
          a.budget.name.toLowerCase().compareTo(b.budget.name.toLowerCase()),
    );
    log.fine(
      "[ReportRepo:_calculateBudgetPerformance] Calculated performance for ${performanceList.length} budgets.",
    );
    return Right(BudgetPerformanceReportData(performanceData: performanceList));
  }

  Color _calculateStatusColor(BudgetHealth health) {
      switch (health) {
      case BudgetHealth.thriving:
        return Colors.green;
      case BudgetHealth.nearingLimit:
        return Colors.orange;
      case BudgetHealth.overLimit:
        return Colors.red;
      case BudgetHealth.unknown:
        return Colors.grey;
    }
  }

  @override
  Future<Either<Failure, GoalProgressReportData>> getGoalProgress({
    List<String>? goalIds,
    bool calculateComparisonRate = false,
  }) async {
    log.info(
      "[ReportRepo] getGoalProgress: Goals=${goalIds?.length ?? 'All Active'}",
    );
    try {
      final goalsResult = await goalRepository.getGoals(
        includeArchived: false,
      );
      if (goalsResult.isLeft())
        return goalsResult.fold(
          (l) => Left(l),
          (_) => const Left(CacheFailure("Failed")),
        );
      final allActiveGoals = goalsResult.getOrElse(() => []);

      final relevantGoals = (goalIds == null || goalIds.isEmpty)
          ? allActiveGoals
          : allActiveGoals.where((g) => goalIds.contains(g.id)).toList();

      if (relevantGoals.isEmpty) {
        log.fine("[ReportRepo] No relevant active goals found.");
        return const Right(GoalProgressReportData(progressData: []));
      }

      final contribResult = await goalContributionRepository
          .getAllContributions();
      if (contribResult.isLeft()) {
        return contribResult.fold(
          (l) => Left(l),
          (_) => const Left(CacheFailure("Failed to fetch contributions")),
        );
      }

      final allContributions = contribResult.getOrElse(() => []);
      final contributionsByGoal = groupBy(
        allContributions,
        (GoalContribution c) => c.goalId,
      );

      final List<GoalProgressData> progressList = [];
      for (final goal in relevantGoals) {
        final goalContribs = contributionsByGoal[goal.id] ?? [];
        final pacing = _calculateGoalPacing(goal);
        progressList.add(
          GoalProgressData(
            goal: goal,
            contributions: goalContribs,
            requiredDailySaving: pacing.daily,
            requiredMonthlySaving: pacing.monthly,
            estimatedCompletionDate: pacing.estimatedCompletion,
          ),
        );
      }

      progressList.sort(
        (a, b) => (a.goal.targetDate ?? DateTime(2100)).compareTo(
          b.goal.targetDate ?? DateTime(2100),
        ),
      );
      log.info(
        "[ReportRepo] Goal progress report generated. Goals: ${progressList.length}",
      );
      return Right(GoalProgressReportData(progressData: progressList));
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getGoalProgress$e$s");
      return Left(
        UnexpectedFailure("Failed to generate goal progress report: $e"),
      );
    }
  }

  ({double? daily, double? monthly, DateTime? estimatedCompletion})
  _calculateGoalPacing(Goal goal) {
    if (goal.isAchieved ||
        goal.targetAmount <= 0 ||
        goal.totalSaved >= goal.targetAmount) {
      return (
        daily: 0.0,
        monthly: 0.0,
        estimatedCompletion: goal.achievedAt ?? DateTime.now(),
      );
    }

    final amountRemaining = goal.amountRemaining;
    double? dailyRate;
    double? monthlyRate;
    DateTime? estimatedCompletion;

    if (goal.targetDate != null) {
      final now = DateTime.now();
      final targetDate = goal.targetDate!;
      if (targetDate.isAfter(now)) {
        final daysRemaining = targetDate.difference(now).inDays;
        if (daysRemaining > 0) {
          dailyRate = amountRemaining / daysRemaining;
          monthlyRate = dailyRate * 30.44;
        } else {
          dailyRate = double.infinity;
          monthlyRate = double.infinity;
        }
      } else {
        dailyRate = double.infinity;
        monthlyRate = double.infinity;
      }
    }
    if (dailyRate != null && dailyRate.isFinite && dailyRate > 0) {
      final daysNeeded = (amountRemaining / dailyRate).ceil();
      estimatedCompletion = DateTime.now().add(Duration(days: daysNeeded));
    } else if (dailyRate == 0 && amountRemaining == 0) {
      estimatedCompletion =
          DateTime.now();
    }

    return (
      daily: dailyRate,
      monthly: monthlyRate,
      estimatedCompletion: estimatedCompletion,
    );
  }

  @override
  Future<Either<Failure, List<TimeSeriesDataPoint>>> getRecentDailySpending({
    int days = 7,
    List<String>? accountIds,
    List<String>? categoryIds,
  }) async {
    log.info("[ReportRepo] getRecentDailySpending: Days=$days");
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).subtract(Duration(days: days - 1));
      final endDateEndOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      final result = await _calculateSpendingOverTime(
        startDate,
        endDateEndOfDay,
        TimeSeriesGranularity.daily,
        accountIds,
        categoryIds,
        TransactionType.expense,
      );

      return result.fold((l) => Left(l), (reportData) {
        final Map<DateTime, double> dataMap = {
          for (var p in reportData.spendingData) p.date: p.currentAmount,
        };
        final List<TimeSeriesDataPoint> filledData = [];
        for (int i = 0; i < days; i++) {
          final date = DateTime(
            startDate.year,
            startDate.month,
            startDate.day + i,
          );
          filledData.add(
            TimeSeriesDataPoint(
              date: date,
              amount: ComparisonValue(
                currentValue: dataMap[date] ?? 0.0,
              ),
            ),
          );
        }
        return Right(filledData);
      });
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getRecentDailySpending$e$s");
      return Left(UnexpectedFailure("Failed to get recent spending data: $e"));
    }
  }

  @override
  Future<Either<Failure, List<TimeSeriesDataPoint>>>
  getRecentDailyContributions(String goalId, {int days = 30}) async {
    log.info(
      "[ReportRepo] getRecentDailyContributions: Goal=$goalId, Days=$days",
    );
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).subtract(Duration(days: days - 1));
      final endDateEndOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      final contribResult = await goalContributionRepository
          .getContributionsForGoal(goalId);
      if (contribResult.isLeft()) {
        return contribResult.fold(
          (l) => Left(l),
          (_) => const Left(CacheFailure("Failed")),
        );
      }
      final allContributions = contribResult.getOrElse(() => []);

      final contributionsInRange = allContributions.where((c) {
        return !c.date.isBefore(startDate) && !c.date.isAfter(endDateEndOfDay);
      }).toList();

      final Map<DateTime, double> aggregatedData = {};
      for (final contribution in contributionsInRange) {
        DateTime periodKey = DateTime(
          contribution.date.year,
          contribution.date.month,
          contribution.date.day,
        );
        aggregatedData.update(
          periodKey,
          (value) => value + contribution.amount,
          ifAbsent: () => contribution.amount,
        );
      }

      final List<TimeSeriesDataPoint> filledData = [];
      for (int i = 0; i < days; i++) {
        final date = DateTime(
          startDate.year,
          startDate.month,
          startDate.day + i,
        );
        filledData.add(
          TimeSeriesDataPoint(
            date: date,
            amount: ComparisonValue(
              currentValue: aggregatedData[date] ?? 0.0,
            ),
          ),
        );
      }
      log.fine(
        "[ReportRepo] Calculated ${filledData.length} daily contribution points for Goal ID $goalId",
      );
      return Right(filledData);
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getRecentDailyContributions$e$s");
      return Left(
        UnexpectedFailure("Failed to get recent contribution data: $e"),
      );
    }
  }
}
