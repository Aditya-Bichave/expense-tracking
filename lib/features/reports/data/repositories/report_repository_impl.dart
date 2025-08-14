// lib/features/reports/data/repositories/report_repository_impl.dart
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart'; // Needed for new method
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart'; // For Color
import 'package:expense_tracker/core/di/service_locator.dart'; // For sl

class ReportRepositoryImpl implements ReportRepository {
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;
  final CategoryRepository categoryRepository;
  final AssetAccountRepository accountRepository;
  final BudgetRepository budgetRepository;
  final GoalRepository goalRepository;
  final GoalContributionRepository goalContributionRepository;

  ReportRepositoryImpl({
    required this.expenseRepository,
    required this.incomeRepository,
    required this.categoryRepository,
    required this.accountRepository,
    required this.budgetRepository,
    required this.goalRepository,
    required this.goalContributionRepository,
  });

  // --- Helper Functions (Refined/Unchanged) ---

  ({DateTime start, DateTime end}) _getPreviousPeriod(
    DateTime currentStart,
    DateTime currentEnd,
  ) {
    final duration = currentEnd.difference(currentStart);
    final prevEnd = currentStart.subtract(const Duration(microseconds: 1));
    final prevStart = prevEnd.subtract(duration);
    return (start: prevStart, end: prevEnd);
  }

  // Generic transaction fetcher (minor adjustment for clarity)
  Future<Either<Failure, List<dynamic>>> _fetchTransactions({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? accountIds,
    List<String>? categoryIds,
    TransactionType? transactionType, // Can be null for both types
  }) async {
    log.fine(
      "[ReportRepo:_fetchTransactions] Fetching: Type=${transactionType?.name ?? 'Both'}, Start=$startDate, End=$endDate, Accs=${accountIds?.length}, Cats=${categoryIds?.length}",
    );
    try {
      List<Future<Either<Failure, List<dynamic>>>> futures = [];

      final bool fetchExpenses =
          transactionType == null || transactionType == TransactionType.expense;
      final bool fetchIncome =
          transactionType == null || transactionType == TransactionType.income;

      // Fetch expenses if needed
      if (fetchExpenses) {
        futures.add(
          expenseRepository
              .getExpenses(
                startDate: startDate,
                endDate: endDate,
                accountId: accountIds?.join(','),
                category: categoryIds?.join(','),
              )
              .then((either) => either.map((list) => list as List<dynamic>)),
        );
      }

      // Fetch income if needed
      if (fetchIncome) {
        futures.add(
          incomeRepository
              .getIncomes(
                startDate: startDate,
                endDate: endDate,
                accountId: accountIds?.join(','),
                category: categoryIds?.join(','),
              )
              .then((either) => either.map((list) => list as List<dynamic>)),
        );
      }

      if (futures.isEmpty) {
        log.warning(
          "[ReportRepo:_fetchTransactions] No transaction types selected for fetching.",
        );
        return const Right(
          [],
        ); // Return empty list if neither type is requested
      }

      final results = await Future.wait(futures);

      List<dynamic> combinedList = [];
      Failure? firstFailure;

      for (final result in results) {
        result.fold(
          (f) => firstFailure ??= f,
          (data) => combinedList.addAll(data),
        );
        if (firstFailure != null) {
          log.warning(
            "[ReportRepo:_fetchTransactions] Failure during fetch: ${firstFailure?.message ?? 'Unknown error'}",
          );
          return Left(
            firstFailure ??
                CacheFailure('Unknown error during transaction fetch'),
          ); // Return first failure or a default
        }
      }

      log.fine(
        "[ReportRepo:_fetchTransactions] Fetched ${combinedList.length} transactions total.",
      );
      return Right(combinedList);
    } catch (e, s) {
      log.severe("[ReportRepo:_fetchTransactions] Error: $e\n$s");
      return Left(UnexpectedFailure("Failed to fetch transactions: $e"));
    }
  }

  // --- Spending By Category Report (Refactored for Comparison) ---

  @override
  Future<Either<Failure, SpendingCategoryReportData>> getSpendingByCategory({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? accountIds,
    List<String>? categoryIds,
    TransactionType? transactionType, // Usually Expense for this report
    bool compareToPrevious = false,
  }) async {
    log.info(
      "[ReportRepo] getSpendingByCategory: Start=$startDate, End=$endDate, Type=${transactionType?.name}, Compare=$compareToPrevious",
    );
    try {
      // Fetch Current Period Data
      final currentDataEither = await _calculateSpendingByCategory(
        startDate,
        endDate,
        accountIds,
        categoryIds,
        transactionType,
      );
      if (currentDataEither.isLeft()) return currentDataEither;
      final currentData = currentDataEither.getOrElse(
        () => throw StateError("Current data fetch failed"),
      );

      // Fetch Previous Period Data (if requested)
      Map<String, CategorySpendingData> previousCategoryMap = {};
      double? previousTotalSpending;
      if (compareToPrevious) {
        final prevDates = _getPreviousPeriod(startDate, endDate);
        final previousDataEither = await _calculateSpendingByCategory(
          prevDates.start,
          prevDates.end,
          accountIds,
          categoryIds,
          transactionType,
        );
        previousDataEither.fold(
          (failure) => log.warning(
            "[ReportRepo] Failed to get previous category spending data for comparison: ${failure.message}",
          ),
          (previousReportData) {
            log.fine("[ReportRepo] Fetched previous period category spending.");
            previousTotalSpending = previousReportData.currentTotalSpending;
            previousCategoryMap = {
              for (var catData in previousReportData.spendingByCategory)
                catData.categoryId: catData,
            };
          },
        );
      }

      // Combine Data with ComparisonValue
      final finalSpendingByCategory = currentData.spendingByCategory.map((
        currentCat,
      ) {
        final prevCatData = previousCategoryMap[currentCat.categoryId];
        return CategorySpendingData(
          categoryId: currentCat.categoryId,
          categoryName: currentCat.categoryName,
          categoryColor: currentCat.categoryColor,
          totalAmount: ComparisonValue<double>(
            // Explicit type
            currentValue: currentCat.currentTotalAmount,
            previousValue: prevCatData?.currentTotalAmount,
          ),
          percentage: currentCat.percentage,
        );
      }).toList();

      return Right(
        SpendingCategoryReportData(
          totalSpending: ComparisonValue<double>(
            // Explicit type
            currentValue: currentData.currentTotalSpending,
            previousValue: previousTotalSpending,
          ),
          spendingByCategory: finalSpendingByCategory,
        ),
      );
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getSpendingByCategory$e$s");
      return Left(
        UnexpectedFailure("Failed to generate category spending report: $e"),
      );
    }
  }

  // Helper to calculate data for a single period
  Future<Either<Failure, SpendingCategoryReportData>>
  _calculateSpendingByCategory(
    DateTime startDate,
    DateTime endDate,
    List<String>? accountIds,
    List<String>? categoryIds,
    TransactionType? transactionType,
  ) async {
    final typeToFetch = transactionType ?? TransactionType.expense;
    if (typeToFetch == TransactionType.income) {
      log.info(
        "[ReportRepo:_calculateSpendingByCategory] Income type requested, returning empty report.",
      );
      return Right(
        SpendingCategoryReportData(
          totalSpending: const ComparisonValue(currentValue: 0),
          spendingByCategory: const [],
        ),
      );
    }

    final transactionResult = await _fetchTransactions(
      startDate: startDate,
      endDate: endDate,
      accountIds: accountIds,
      categoryIds: categoryIds,
      transactionType: typeToFetch,
    );

    if (transactionResult.isLeft()) {
      return transactionResult.fold(
        (l) => Left(l),
        (_) => const Left(CacheFailure("Transaction fetch failed")),
      );
    }

    final filteredExpenses = transactionResult
        .getOrElse(() => [])
        .cast<ExpenseModel>();

    if (filteredExpenses.isEmpty) {
      log.fine(
        "[ReportRepo:_calculateSpendingByCategory] No expenses found for the period.",
      );
      return Right(
        SpendingCategoryReportData(
          totalSpending: const ComparisonValue(currentValue: 0),
          spendingByCategory: const [],
        ),
      );
    }

    // Fetch categories for names/colors
    final categoryResult = await categoryRepository.getAllCategories();
    if (categoryResult.isLeft()) {
      return categoryResult.fold(
        (l) => Left(l),
        (_) => const Left(CacheFailure("Category fetch failed")),
      );
    }
    final categoryMap = {
      for (var cat in categoryResult.getOrElse(() => [])) cat.id: cat,
    };
    final uncategorized = Category.uncategorized;

    final Map<String, double> spendingMap = {};
    double totalSpending = 0;

    for (final expense in filteredExpenses) {
      final categoryId = expense.categoryId ?? uncategorized.id;
      spendingMap.update(
        categoryId,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
      totalSpending += expense.amount;
    }

    final List<CategorySpendingData> reportData = spendingMap.entries.map((
      entry,
    ) {
      final categoryId = entry.key;
      final amount = entry.value;
      final category =
          categoryMap[categoryId] ?? uncategorized.copyWith(id: categoryId);
      final percentage = totalSpending > 0 ? (amount / totalSpending) : 0.0;
      return CategorySpendingData(
        categoryId: categoryId,
        categoryName: category.name,
        categoryColor: category.displayColor,
        totalAmount: ComparisonValue(
          currentValue: amount,
        ), // Only current value here
        percentage: percentage,
      );
    }).toList();

    reportData.sort(
      (a, b) => b.currentTotalAmount.compareTo(a.currentTotalAmount),
    );

    log.fine(
      "[ReportRepo:_calculateSpendingByCategory] Calculated spending for ${reportData.length} categories. Total: $totalSpending",
    );
    return Right(
      SpendingCategoryReportData(
        totalSpending: ComparisonValue(
          currentValue: totalSpending,
        ), // Only current value here
        spendingByCategory: reportData,
      ),
    );
  }

  // --- Spending Over Time Report (Refactored for Comparison) ---

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
    log.info(
      "[ReportRepo] getSpendingOverTime: Granularity=$granularity, Type=${transactionType?.name}, Compare=$compareToPrevious",
    );
    try {
      // Fetch Current Period Data
      final currentDataEither = await _calculateSpendingOverTime(
        startDate,
        endDate,
        granularity,
        accountIds,
        categoryIds,
        transactionType,
      );
      if (currentDataEither.isLeft()) return currentDataEither;
      final currentData = currentDataEither.getOrElse(
        () => throw StateError("Current data calculation failed"),
      );

      // Fetch Previous Period Data (if requested)
      Map<DateTime, TimeSeriesDataPoint> previousDataMap = {};
      if (compareToPrevious) {
        final prevDates = _getPreviousPeriod(startDate, endDate);
        final previousDataEither = await _calculateSpendingOverTime(
          prevDates.start,
          prevDates.end,
          granularity,
          accountIds,
          categoryIds,
          transactionType,
        );
        previousDataEither.fold(
          (failure) => log.warning(
            "[ReportRepo] Failed to get previous time series data for comparison: ${failure.message}",
          ),
          (previousReportData) {
            log.fine("[ReportRepo] Fetched previous period time series data.");
            previousDataMap = {
              for (var p in previousReportData.spendingData) p.date: p,
            };
          },
        );
      }

      // Combine Data with ComparisonValue
      final List<TimeSeriesDataPoint> finalSpendingData = currentData
          .spendingData
          .map((currentPoint) {
            final prevPoint = previousDataMap[currentPoint.date];
            return TimeSeriesDataPoint(
              date: currentPoint.date,
              amount: ComparisonValue<double>(
                // Explicit type
                currentValue: currentPoint.currentAmount,
                previousValue: prevPoint?.currentAmount,
              ),
            );
          })
          .toList();

      return Right(
        SpendingTimeReportData(
          spendingData: finalSpendingData,
          granularity: currentData.granularity,
        ),
      );
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getSpendingOverTime$e$s");
      return Left(
        UnexpectedFailure("Failed to generate spending over time report: $e"),
      );
    }
  }

  // Helper for single period calculation
  Future<Either<Failure, SpendingTimeReportData>> _calculateSpendingOverTime(
    DateTime startDate,
    DateTime endDate,
    TimeSeriesGranularity granularity,
    List<String>? accountIds,
    List<String>? categoryIds,
    TransactionType? transactionType,
  ) async {
    final typeToFetch = transactionType ?? TransactionType.expense;

    final transactionResult = await _fetchTransactions(
      startDate: startDate,
      endDate: endDate,
      accountIds: accountIds,
      categoryIds: categoryIds,
      transactionType: typeToFetch,
    );

    if (transactionResult.isLeft()) {
      return transactionResult.fold(
        (l) => Left(l),
        (_) => const Left(CacheFailure("Transaction fetch failed")),
      );
    }

    final transactions = transactionResult.getOrElse(() => []);
    final filteredTxns = (typeToFetch == TransactionType.income)
        ? transactions.whereType<IncomeModel>().toList()
        : transactions.whereType<ExpenseModel>().toList();

    if (filteredTxns.isEmpty) {
      log.fine(
        "[ReportRepo:_calculateSpendingOverTime] No transactions found for the period/type.",
      );
      return Right(
        SpendingTimeReportData(spendingData: [], granularity: granularity),
      );
    }

    final Map<DateTime, double> aggregatedData = {};
    for (final hiveObject in filteredTxns) {
      // Assuming the transaction type is TransactionModel, adjust if different
      final txn = hiveObject as ExpenseModel;
      DateTime periodKey;
      switch (granularity) {
        case TimeSeriesGranularity.daily:
          periodKey = DateTime(txn.date.year, txn.date.month, txn.date.day);
          break;
        case TimeSeriesGranularity.weekly:
          int daysToSubtract =
              txn.date.weekday - 1; // Assuming Monday is start of week (1)
          periodKey = DateTime(
            txn.date.year,
            txn.date.month,
            txn.date.day - daysToSubtract,
          );
          break;
        case TimeSeriesGranularity.monthly:
          periodKey = DateTime(txn.date.year, txn.date.month, 1);
          break;
      }
      aggregatedData.update(
        periodKey,
        (value) => value + txn.amount,
        ifAbsent: () => txn.amount,
      );
    }

    final List<TimeSeriesDataPoint> reportData = aggregatedData.entries
        .map(
          (entry) => TimeSeriesDataPoint(
            date: entry.key,
            amount: ComparisonValue(
              currentValue: entry.value,
            ), // Only current value here
          ),
        )
        .toList();

    reportData.sort((a, b) => a.date.compareTo(b.date));

    log.fine(
      "[ReportRepo:_calculateSpendingOverTime] Aggregated ${reportData.length} data points for granularity ${granularity.name}",
    );
    return Right(
      SpendingTimeReportData(
        spendingData: reportData,
        granularity: granularity,
      ),
    );
  }

  // --- Income vs Expense Report (Refactored for Comparison) ---

  @override
  Future<Either<Failure, IncomeExpenseReportData>> getIncomeVsExpense({
    required DateTime startDate,
    required DateTime endDate,
    required IncomeExpensePeriodType periodType,
    List<String>? accountIds,
    bool compareToPrevious = false,
  }) async {
    log.info(
      "[ReportRepo] getIncomeVsExpense: Period=$periodType, Compare=$compareToPrevious",
    );
    try {
      // Fetch Current Period Data
      final currentDataEither = await _calculateIncomeVsExpense(
        startDate,
        endDate,
        periodType,
        accountIds,
      );
      if (currentDataEither.isLeft()) return currentDataEither;
      final currentData = currentDataEither.getOrElse(
        () => throw StateError("Current data calculation failed"),
      );

      // Fetch Previous Period Data (if requested)
      Map<DateTime, IncomeExpensePeriodData> previousDataMap = {};
      if (compareToPrevious) {
        final prevDates = _getPreviousPeriod(startDate, endDate);
        final previousDataEither = await _calculateIncomeVsExpense(
          prevDates.start,
          prevDates.end,
          periodType,
          accountIds,
        );
        previousDataEither.fold(
          (failure) => log.warning(
            "[ReportRepo] Failed to get previous income/expense data for comparison: ${failure.message}",
          ),
          (previousReportData) {
            log.fine(
              "[ReportRepo] Fetched previous period income/expense data.",
            );
            previousDataMap = {
              for (var p in previousReportData.periodData) p.periodStart: p,
            };
          },
        );
      }

      // Combine Data with ComparisonValue
      final List<IncomeExpensePeriodData> finalPeriodData = currentData
          .periodData
          .map((currentPoint) {
            final prevPoint = previousDataMap[currentPoint.periodStart];
            return IncomeExpensePeriodData(
              periodStart: currentPoint.periodStart,
              totalIncome: ComparisonValue<double>(
                // Explicit type
                currentValue: currentPoint.currentTotalIncome,
                previousValue: prevPoint?.currentTotalIncome,
              ),
              totalExpense: ComparisonValue<double>(
                // Explicit type
                currentValue: currentPoint.currentTotalExpense,
                previousValue: prevPoint?.currentTotalExpense,
              ),
            );
          })
          .toList();

      return Right(
        IncomeExpenseReportData(
          periodData: finalPeriodData,
          periodType: currentData.periodType,
        ),
      );
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getIncomeVsExpense$e$s");
      return Left(
        UnexpectedFailure("Failed to generate income vs expense report: $e"),
      );
    }
  }

  // Helper for single period calculation
  Future<Either<Failure, IncomeExpenseReportData>> _calculateIncomeVsExpense(
    DateTime startDate,
    DateTime endDate,
    IncomeExpensePeriodType periodType,
    List<String>? accountIds,
  ) async {
    final transactionResult = await _fetchTransactions(
      startDate: startDate,
      endDate: endDate,
      accountIds: accountIds,
      transactionType: null,
    ); // Fetch both

    if (transactionResult.isLeft()) {
      return transactionResult.fold(
        (l) => Left(l),
        (_) => const Left(CacheFailure("Transaction fetch failed")),
      );
    }

    final transactions = transactionResult.getOrElse(() => []);
    final Map<DateTime, ({double income, double expense})> aggregatedData = {};

    for (final txn in transactions) {
      final DateTime date;
      final double amount;
      final bool isIncome;

      if (txn is ExpenseModel) {
        date = txn.date;
        amount = txn.amount;
        isIncome = false;
      } else if (txn is IncomeModel) {
        date = txn.date;
        amount = txn.amount;
        isIncome = true;
      } else {
        log.warning(
          "[ReportRepo:_calculateIncomeVsExpense] Unknown transaction type: ${txn.runtimeType}",
        );
        continue;
      }

      final periodKeyDate = periodType == IncomeExpensePeriodType.monthly
          ? DateTime(date.year, date.month, 1)
          : DateTime(date.year, 1, 1);

      final current =
          aggregatedData[periodKeyDate] ?? (income: 0.0, expense: 0.0);
      aggregatedData[periodKeyDate] = isIncome
          ? (income: current.income + amount, expense: current.expense)
          : (income: current.income, expense: current.expense + amount);
    }

    final List<IncomeExpensePeriodData> reportData = aggregatedData.entries
        .map(
          (entry) => IncomeExpensePeriodData(
            periodStart: entry.key,
            totalIncome: ComparisonValue(
              currentValue: entry.value.income,
            ), // Only current
            totalExpense: ComparisonValue(currentValue: entry.value.expense),
          ), // Only current
        )
        .toList();

    reportData.sort((a, b) => a.periodStart.compareTo(b.periodStart));
    log.fine(
      "[ReportRepo:_calculateIncomeVsExpense] Aggregated ${reportData.length} data points for period type ${periodType.name}",
    );
    return Right(
      IncomeExpenseReportData(periodData: reportData, periodType: periodType),
    );
  }

  // --- Budget Performance Report (Refactored for Comparison) ---

  @override
  Future<Either<Failure, BudgetPerformanceReportData>> getBudgetPerformance({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? budgetIds,
    List<String>? accountIds,
    bool compareToPrevious = false,
  }) async {
    log.info(
      "[ReportRepo] getBudgetPerformance: Start=$startDate, End=$endDate, Compare=$compareToPrevious",
    );
    try {
      // Fetch Current Period Data
      final currentPerformanceEither = await _calculateBudgetPerformance(
        startDate,
        endDate,
        budgetIds,
        accountIds,
      );
      if (currentPerformanceEither.isLeft()) return currentPerformanceEither;
      final currentPerformanceReport = currentPerformanceEither.getOrElse(
        () => throw StateError("Current data failed"),
      );

      // Fetch Previous Period Data (if requested)
      Map<String, BudgetPerformanceData> previousDataMap = {};
      if (compareToPrevious) {
        final prevDates = _getPreviousPeriod(startDate, endDate);
        final previousPerformanceEither = await _calculateBudgetPerformance(
          prevDates.start,
          prevDates.end,
          budgetIds,
          accountIds,
        );
        previousPerformanceEither.fold(
          (failure) => log.warning(
            "[ReportRepo] Failed to get previous budget performance for comparison: ${failure.message}",
          ),
          (previousReportData) {
            log.fine(
              "[ReportRepo] Fetched previous period budget performance.",
            );
            previousDataMap = {
              for (var item in previousReportData.performanceData)
                item.budget.id: item,
            };
          },
        );
      }

      // Combine Data with ComparisonValue
      final List<BudgetPerformanceData> finalPerformanceData =
          currentPerformanceReport.performanceData.map((currentP) {
            final prevP = previousDataMap[currentP.budget.id];
            double? prevVariancePercent;
            if (prevP != null && prevP.budget.targetAmount > 0) {
              prevVariancePercent =
                  (prevP.currentVarianceAmount / prevP.budget.targetAmount) *
                  100;
            } else if (prevP != null && prevP.currentActualSpending > 0) {
              prevVariancePercent =
                  double.negativeInfinity; // Spent something with 0 target
            } else if (prevP != null) {
              prevVariancePercent = 0.0; // Spent 0 with 0 target
            }

            return BudgetPerformanceData(
              budget: currentP.budget,
              actualSpending: ComparisonValue<double>(
                // Explicit type
                currentValue: currentP.currentActualSpending,
                previousValue: prevP?.currentActualSpending,
              ),
              varianceAmount: ComparisonValue<double>(
                // Explicit type
                currentValue: currentP.currentVarianceAmount,
                previousValue: prevP?.currentVarianceAmount,
              ),
              currentVariancePercent: currentP.currentVariancePercent,
              previousVariancePercent:
                  prevVariancePercent, // Calculated from previous data
              health: currentP.health,
              statusColor: currentP.statusColor,
            );
          }).toList();

      // Add previous data list to the final report object
      final previousPerformanceList = compareToPrevious
          ? previousDataMap.values.toList()
          : null;

      return Right(
        BudgetPerformanceReportData(
          performanceData: finalPerformanceData,
          previousPerformanceData:
              previousPerformanceList, // Added previous data
        ),
      );
    } catch (e, s) {
      log.severe("[ReportRepo] Error in getBudgetPerformance$e$s");
      return Left(
        UnexpectedFailure("Failed to generate budget performance report: $e"),
      );
    }
  }

  // Helper for single period calculation
  Future<Either<Failure, BudgetPerformanceReportData>>
  _calculateBudgetPerformance(
    DateTime startDate,
    DateTime endDate,
    List<String>? budgetIds,
    List<String>? accountIds,
  ) async {
    final budgetsResult = await budgetRepository.getBudgets();
    if (budgetsResult.isLeft())
      return budgetsResult.fold(
        (l) => Left(l),
        (_) => const Left(CacheFailure("Failed to fetch budgets")),
      );
    final allBudgets = budgetsResult.getOrElse(() => []);
    final relevantBudgets = (budgetIds == null || budgetIds.isEmpty)
        ? allBudgets
        : allBudgets.where((b) => budgetIds.contains(b.id)).toList();

    if (relevantBudgets.isEmpty) {
      log.fine(
        "[ReportRepo:_calculateBudgetPerformance] No relevant budgets found for the period.",
      );
      return const Right(BudgetPerformanceReportData(performanceData: []));
    }

    final expenseResult = await expenseRepository.getExpenses(
      startDate: startDate,
      endDate: endDate,
      accountId: accountIds?.join(','),
    );
    if (expenseResult.isLeft())
      return expenseResult.fold(
        (l) => Left(l),
        (_) => const Left(CacheFailure("Expense fetch failed")),
      );
    final allExpensesInRange = expenseResult.getOrElse(() => []);

    // Define colors (could move to theme constants)
    const thrivingColor = Colors.green;
    const nearingLimitColor = Colors.orange;
    const overLimitColor = Colors.red;

    List<BudgetPerformanceData> performanceList = [];

    for (final budget in relevantBudgets) {
      // Determine effective dates for calculation based on budget period type vs report period
      final (effStart, effEnd) =
          (budget.period == BudgetPeriodType.oneTime &&
              budget.startDate != null &&
              budget.endDate != null)
          ? (
              budget.startDate!,
              budget.endDate!,
            ) // Use budget's dates if one-time
          : (startDate, endDate); // Use report range dates if recurring/overall

      // Filter expenses for *this* budget within the *effective* date range
      final double spent = allExpensesInRange
          .where((exp) {
            // Ensure expense date falls within the effective period for the budget
            final endDateInclusive = effEnd
                .add(const Duration(days: 1))
                .subtract(const Duration(microseconds: 1));
            bool dateMatch =
                !exp.date.isBefore(effStart) &&
                !exp.date.isAfter(endDateInclusive);
            if (!dateMatch) return false;

            // Check category match
            if (budget.type == BudgetType.overall) return true;
            if (budget.type == BudgetType.categorySpecific) {
              return budget.categoryIds?.contains(exp.categoryId) ?? false;
            }
            return false; // Should not happen
          })
          .fold(0.0, (sum, exp) => sum + exp.amount);

      final target = budget.targetAmount;
      final variance = target - spent;
      final variancePercent = target > 0
          ? (variance / target) * 100
          : (spent > 0 ? double.negativeInfinity : 0.0); // Handle 0 target

      // Use BudgetWithStatus helper for consistency
      final statusResult = BudgetWithStatus.calculate(
        budget: budget,
        amountSpent: spent,
        thrivingColor: thrivingColor,
        nearingLimitColor: nearingLimitColor,
        overLimitColor: overLimitColor,
      );

      performanceList.add(
        BudgetPerformanceData(
          budget: budget,
          actualSpending: ComparisonValue(currentValue: spent), // Only current
          varianceAmount: ComparisonValue(
            currentValue: variance,
          ), // Only current
          currentVariancePercent: variancePercent,
          // No previous data in this helper
          health: statusResult.health,
          statusColor: statusResult.statusColor,
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

  // --- Goal Progress Report ---
  @override
  Future<Either<Failure, GoalProgressReportData>> getGoalProgress({
    List<String>? goalIds,
    bool calculateComparisonRate = false,
  }) async {
    // No comparison needed for V1
    log.info(
      "[ReportRepo] getGoalProgress: Goals=${goalIds?.length ?? 'All Active'}",
    );
    try {
      final goalsResult = await goalRepository.getGoals(
        includeArchived: false,
      ); // Only active goals
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
        final pacing = _calculateGoalPacing(goal); // Use existing simple pacing
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
          monthlyRate = dailyRate * 30.44; // Approx days in month
        } else {
          dailyRate = double.infinity; // Target is today or passed
          monthlyRate = double.infinity;
        }
      } else {
        dailyRate = double.infinity; // Target date passed
        monthlyRate = double.infinity;
      }
    }
    // Estimate completion based on daily rate ONLY if target date exists and rate is positive finite
    if (dailyRate != null && dailyRate.isFinite && dailyRate > 0) {
      final daysNeeded = (amountRemaining / dailyRate).ceil();
      estimatedCompletion = DateTime.now().add(Duration(days: daysNeeded));
    } else if (dailyRate == 0 && amountRemaining == 0) {
      estimatedCompletion =
          DateTime.now(); // Already achieved today essentially
    }

    return (
      daily: dailyRate,
      monthly: monthlyRate,
      estimatedCompletion: estimatedCompletion,
    );
  }

  // --- REFINED: getRecentDailySpending - Returns List<TimeSeriesDataPoint> ---
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
      ); // Explicitly expense

      return result.fold((l) => Left(l), (reportData) {
        // Fill missing days with 0
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
              ), // Only current needed
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

  // --- ADDED: getRecentDailyContributions (Example) ---
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

      // 1. Fetch contributions for the goal
      final contribResult = await goalContributionRepository
          .getContributionsForGoal(goalId);
      if (contribResult.isLeft()) {
        return contribResult.fold(
          (l) => Left(l),
          (_) => const Left(CacheFailure("Failed")),
        );
      }
      final allContributions = contribResult.getOrElse(() => []);

      // 2. Filter contributions by date range
      final contributionsInRange = allContributions.where((c) {
        return !c.date.isBefore(startDate) && !c.date.isAfter(endDateEndOfDay);
      }).toList();

      // 3. Aggregate by day
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

      // 4. Fill missing days with 0 and create TimeSeriesDataPoints
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
            ), // Only current needed
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
