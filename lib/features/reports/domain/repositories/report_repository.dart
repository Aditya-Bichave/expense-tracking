// lib/features/reports/domain/repositories/report_repository.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';

abstract class ReportRepository {
  Future<Either<Failure, SpendingCategoryReportData>> getSpendingByCategory({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? accountIds,
    List<String>? categoryIds,
    TransactionType? transactionType,
    bool compareToPrevious = false,
  });

  Future<Either<Failure, SpendingTimeReportData>> getSpendingOverTime({
    required DateTime startDate,
    required DateTime endDate,
    required TimeSeriesGranularity granularity,
    List<String>? accountIds,
    List<String>? categoryIds,
    TransactionType? transactionType,
    bool compareToPrevious = false,
  });

  Future<Either<Failure, IncomeExpenseReportData>> getIncomeVsExpense({
    required DateTime startDate,
    required DateTime endDate,
    required IncomeExpensePeriodType periodType,
    List<String>? accountIds,
    bool compareToPrevious = false,
  });

  Future<Either<Failure, BudgetPerformanceReportData>> getBudgetPerformance({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? budgetIds,
    List<String>? accountIds,
    bool compareToPrevious = false,
  });

  Future<Either<Failure, GoalProgressReportData>> getGoalProgress({
    List<String>? goalIds,
    bool calculateComparisonRate = false,
  });

  // --- REFINED: Returns List<TimeSeriesDataPoint> ---
  Future<Either<Failure, List<TimeSeriesDataPoint>>> getRecentDailySpending({
    int days = 7,
    List<String>? accountIds,
    List<String>? categoryIds,
  });

  // --- ADDED: Method for goal sparkline data ---
  Future<Either<Failure, List<TimeSeriesDataPoint>>>
      getRecentDailyContributions(
    String goalId, {
    int days = 30, // Default to 30 days for goals
  });
}
