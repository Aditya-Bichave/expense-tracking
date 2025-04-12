// lib/features/reports/domain/entities/report_data.dart
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:flutter/material.dart'; // For Color

// --- Comparison Value Helper ---
class ComparisonValue<T extends num> extends Equatable {
  final T currentValue;
  final T? previousValue; // Nullable if no comparison data

  const ComparisonValue({required this.currentValue, this.previousValue});

  // Calculate absolute change
  double? get absoluteChange => previousValue == null
      ? null
      : currentValue.toDouble() - previousValue!.toDouble();

  // Calculate percentage change
  double? get percentageChange {
    if (previousValue == null) return null; // No comparison possible
    final prev = previousValue!.toDouble();
    final current = currentValue.toDouble();
    if (prev == 0) {
      // Handle division by zero
      if (current == 0) return 0.0; // 0 to 0 is 0% change
      return current > 0 ? double.infinity : double.negativeInfinity;
    }
    // Default calculation
    return ((current - prev) / prev.abs()) * 100;
  }

  @override
  List<Object?> get props => [currentValue, previousValue];
}

// --- Spending by Category Report ---
class CategorySpendingData extends Equatable {
  final String categoryId;
  final String categoryName;
  final Color categoryColor;
  final ComparisonValue<double> totalAmount; // Use ComparisonValue
  final double percentage; // Percentage of current total

  // Getter for current value (convenience)
  double get currentTotalAmount => totalAmount.currentValue;

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
  final ComparisonValue<double> totalSpending; // Use ComparisonValue
  final List<CategorySpendingData> spendingByCategory;

  // Getter for current value (convenience)
  double get currentTotalSpending => totalSpending.currentValue;

  const SpendingCategoryReportData({
    required this.totalSpending,
    required this.spendingByCategory,
  });

  @override
  List<Object?> get props => [totalSpending, spendingByCategory];

  get previousSpendingByCategory => null;
}

// --- Spending Over Time Report ---
class TimeSeriesDataPoint extends Equatable {
  final DateTime date;
  final ComparisonValue<double> amount; // Use ComparisonValue

  // Getter for current value (convenience)
  double get currentAmount => amount.currentValue;

  const TimeSeriesDataPoint({required this.date, required this.amount});

  @override
  List<Object?> get props => [date, amount];
}

enum TimeSeriesGranularity { daily, weekly, monthly }

class SpendingTimeReportData extends Equatable {
  final List<TimeSeriesDataPoint> spendingData;
  final TimeSeriesGranularity granularity;

  const SpendingTimeReportData({
    required this.spendingData,
    required this.granularity,
  });
  @override
  List<Object?> get props => [spendingData, granularity];
}

// --- Income vs Expense Report ---
class IncomeExpensePeriodData extends Equatable {
  final DateTime periodStart;
  final ComparisonValue<double> totalIncome; // Use ComparisonValue
  final ComparisonValue<double> totalExpense; // Use ComparisonValue

  // Calculated Net Flow using ComparisonValue
  ComparisonValue<double> get netFlow => ComparisonValue(
        currentValue: totalIncome.currentValue - totalExpense.currentValue,
        previousValue: (totalIncome.previousValue != null &&
                totalExpense.previousValue != null)
            ? totalIncome.previousValue! - totalExpense.previousValue!
            : null,
      );

  // Getters for current values (convenience)
  double get currentTotalIncome => totalIncome.currentValue;
  double get currentTotalExpense => totalExpense.currentValue;
  double get currentNetFlow => netFlow.currentValue;

  const IncomeExpensePeriodData({
    required this.periodStart,
    required this.totalIncome,
    required this.totalExpense,
  });
  @override
  List<Object?> get props => [periodStart, totalIncome, totalExpense];
}

enum IncomeExpensePeriodType { monthly, yearly }

class IncomeExpenseReportData extends Equatable {
  final List<IncomeExpensePeriodData> periodData;
  final IncomeExpensePeriodType periodType;

  const IncomeExpenseReportData(
      {required this.periodData, required this.periodType});
  @override
  List<Object?> get props => [periodData, periodType];
}

// --- Budget Performance Report ---
class BudgetPerformanceData extends Equatable {
  final Budget budget;
  final ComparisonValue<double> actualSpending; // Use ComparisonValue
  final ComparisonValue<double> varianceAmount; // Use ComparisonValue
  final double currentVariancePercent; // Percentage for current period
  final double?
      previousVariancePercent; // Percentage for previous period (nullable)
  final BudgetHealth health;
  final Color statusColor;

  // Getters for current values (convenience)
  double get currentActualSpending => actualSpending.currentValue;
  double get currentVarianceAmount => varianceAmount.currentValue;

  const BudgetPerformanceData({
    required this.budget,
    required this.actualSpending,
    required this.varianceAmount,
    required this.currentVariancePercent,
    this.previousVariancePercent,
    required this.health,
    required this.statusColor,
  });

  // Calculate change in variance percentage
  double? get varianceChangePercent {
    if (previousVariancePercent == null) return null;
    final prevVP = previousVariancePercent!;
    final currVP = currentVariancePercent;

    if (prevVP.isInfinite || prevVP.isNaN || currVP.isNaN) {
      // If previous was infinite or either is NaN, change is undefined/meaningless
      return null;
    }
    if (currVP.isInfinite) {
      // Changing *to* infinite variance
      return currVP; // Return the infinite value itself
    }

    // Calculate percentage point change
    return currVP - prevVP;
  }

  @override
  List<Object?> get props => [
        budget,
        actualSpending,
        varianceAmount,
        currentVariancePercent,
        previousVariancePercent,
        health,
        statusColor
      ];
}

class BudgetPerformanceReportData extends Equatable {
  final List<BudgetPerformanceData> performanceData;
  // --- ADDED: Store previous data explicitly for comparison logic in UI/Export ---
  final List<BudgetPerformanceData>? previousPerformanceData;
  // --- END ADD ---

  const BudgetPerformanceReportData(
      {required this.performanceData,
      this.previousPerformanceData}); // Added optional param

  @override
  List<Object?> get props =>
      [performanceData, previousPerformanceData]; // Added previous data
}

// --- Goal Progress Report ---
class GoalProgressData extends Equatable {
  final Goal goal;
  final List<GoalContribution>
      contributions; // Full contribution history for the goal
  final double? requiredDailySaving; // Pacing info
  final double? requiredMonthlySaving;
  final DateTime? estimatedCompletionDate;

  const GoalProgressData({
    required this.goal,
    required this.contributions,
    this.requiredDailySaving,
    this.requiredMonthlySaving,
    this.estimatedCompletionDate,
  });

  @override
  List<Object?> get props => [
        goal,
        contributions,
        requiredDailySaving,
        requiredMonthlySaving,
        estimatedCompletionDate
      ];
}

class GoalProgressReportData extends Equatable {
  final List<GoalProgressData> progressData;
  const GoalProgressReportData({required this.progressData});
  @override
  List<Object?> get props => [progressData];
}
