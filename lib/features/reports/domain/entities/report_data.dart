// lib/features/reports/domain/entities/report_data.dart
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:flutter/material.dart'; // For Color

// --- Spending by Category Report ---
class CategorySpendingData extends Equatable {
  /* ... unchanged ... */
  final String categoryId;
  final String categoryName;
  final Color categoryColor;
  final double totalAmount;
  final double percentage;

  const CategorySpendingData({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.totalAmount,
    required this.percentage,
  });

  @override
  List<Object?> get props =>
      [categoryId, categoryName, categoryColor, totalAmount, percentage];
}

class SpendingCategoryReportData extends Equatable {
  /* ... unchanged ... */
  final double totalSpending;
  final List<CategorySpendingData> spendingByCategory;
  // --- ADDED Comparison Data ---
  final double? previousTotalSpending;
  final List<CategorySpendingData>? previousSpendingByCategory;

  const SpendingCategoryReportData({
    required this.totalSpending,
    required this.spendingByCategory,
    this.previousTotalSpending,
    this.previousSpendingByCategory,
  });

  // Helper for % change
  double? get totalSpendingChangePercent {
    if (previousTotalSpending == null || previousTotalSpending == 0)
      return null;
    return ((totalSpending - previousTotalSpending!) / previousTotalSpending!);
  }

  @override
  List<Object?> get props => [
        totalSpending,
        spendingByCategory,
        previousTotalSpending,
        previousSpendingByCategory
      ];
}

// --- Spending Over Time Report ---
class TimeSeriesDataPoint extends Equatable {
  /* ... unchanged ... */
  final DateTime date;
  final double amount;
  const TimeSeriesDataPoint({required this.date, required this.amount});
  @override
  List<Object?> get props => [date, amount];
}

enum TimeSeriesGranularity { daily, weekly, monthly }

class SpendingTimeReportData extends Equatable {
  /* ... unchanged ... */
  final List<TimeSeriesDataPoint> spendingData;
  final TimeSeriesGranularity granularity;
  // --- ADDED Comparison Data ---
  final List<TimeSeriesDataPoint>? previousSpendingData;

  const SpendingTimeReportData({
    required this.spendingData,
    required this.granularity,
    this.previousSpendingData,
  });
  @override
  List<Object?> get props => [spendingData, granularity, previousSpendingData];
}

// --- Income vs Expense Report ---
class IncomeExpensePeriodData extends Equatable {
  /* ... unchanged ... */
  final DateTime periodStart;
  final double totalIncome;
  final double totalExpense;
  double get netFlow => totalIncome - totalExpense;
  const IncomeExpensePeriodData(
      {required this.periodStart,
      required this.totalIncome,
      required this.totalExpense});
  @override
  List<Object?> get props => [periodStart, totalIncome, totalExpense];
}

enum IncomeExpensePeriodType { monthly, yearly }

class IncomeExpenseReportData extends Equatable {
  /* ... unchanged ... */
  final List<IncomeExpensePeriodData> periodData;
  final IncomeExpensePeriodType periodType;
  // --- ADDED Comparison Data ---
  final List<IncomeExpensePeriodData>? previousPeriodData;

  const IncomeExpenseReportData(
      {required this.periodData,
      required this.periodType,
      this.previousPeriodData});
  @override
  List<Object?> get props => [periodData, periodType, previousPeriodData];
}

// --- Budget Performance Report ---
class BudgetPerformanceData extends Equatable {
  final Budget budget;
  final double actualSpending;
  final double varianceAmount; // target - actual
  final double variancePercent; // varianceAmount / target * 100
  final BudgetHealth health;
  final Color statusColor;

  const BudgetPerformanceData({
    required this.budget,
    required this.actualSpending,
    required this.varianceAmount,
    required this.variancePercent,
    required this.health,
    required this.statusColor,
  });

  @override
  List<Object?> get props => [
        budget,
        actualSpending,
        varianceAmount,
        variancePercent,
        health,
        statusColor
      ];
}

class BudgetPerformanceReportData extends Equatable {
  final List<BudgetPerformanceData> performanceData;
  // --- ADDED Comparison Data ---
  // Could compare overall budget variance or individual budget variances
  final double? previousTotalVariance; // Example
  final List<BudgetPerformanceData>? previousPerformanceData;

  const BudgetPerformanceReportData(
      {required this.performanceData,
      this.previousTotalVariance,
      this.previousPerformanceData});

  @override
  List<Object?> get props =>
      [performanceData, previousTotalVariance, previousPerformanceData];
}

// --- Goal Progress Report ---
class GoalProgressData extends Equatable {
  final Goal goal;
  final List<GoalContribution> contributions; // Recent or all contributions?
  // Add pacing info if calculated
  final double? neededPerMonth; // Example pacing metric

  const GoalProgressData({
    required this.goal,
    required this.contributions,
    this.neededPerMonth,
  });

  @override
  List<Object?> get props => [goal, contributions, neededPerMonth];
}

class GoalProgressReportData extends Equatable {
  final List<GoalProgressData> progressData;
  // Add comparison data if applicable (e.g., previous contribution rate)
  final Map<String, double>? previousContributionRate; // Example <goalId, rate>

  const GoalProgressReportData(
      {required this.progressData, this.previousContributionRate});

  @override
  List<Object?> get props => [progressData, previousContributionRate];
}
