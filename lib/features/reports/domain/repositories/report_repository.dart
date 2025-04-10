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
    // --- ADDED ---
    bool compareToPrevious = false, // Flag to fetch comparison data
  });

  Future<Either<Failure, SpendingTimeReportData>> getSpendingOverTime({
    required DateTime startDate,
    required DateTime endDate,
    required TimeSeriesGranularity granularity,
    List<String>? accountIds,
    List<String>? categoryIds,
    // --- ADDED ---
    bool compareToPrevious = false,
  });

  Future<Either<Failure, IncomeExpenseReportData>> getIncomeVsExpense({
    required DateTime startDate,
    required DateTime endDate,
    required IncomeExpensePeriodType periodType, // Aggregate monthly or yearly
    List<String>? accountIds,
    // --- ADDED ---
    bool compareToPrevious = false,
  });

  // --- ADDED Budget Performance ---
  Future<Either<Failure, BudgetPerformanceReportData>> getBudgetPerformance({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? budgetIds, // Filter by specific budgets
    // --- ADDED ---
    bool compareToPrevious = false,
  });

  // --- ADDED Goal Progress ---
  Future<Either<Failure, GoalProgressReportData>> getGoalProgress({
    List<String>? goalIds, // Filter by specific goals (usually all active)
    // --- ADDED ---
    // Comparison might be more complex (e.g., rate change)
    bool calculateComparisonRate = false,
  });

  // Add methods for Net Worth later...
}
