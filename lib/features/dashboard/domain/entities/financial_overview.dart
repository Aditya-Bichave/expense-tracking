// lib/features/dashboard/domain/entities/financial_overview.dart
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart'; // For TimeSeriesDataPoint

class FinancialOverview extends Equatable {
  final double totalIncome;
  final double totalExpenses;
  final double netFlow;
  final double overallBalance;
  final List<AssetAccount> accounts;
  final Map<String, double> accountBalances;
  final List<BudgetWithStatus> activeBudgetsSummary;
  final List<Goal> activeGoalsSummary;
  final List<TimeSeriesDataPoint>
  recentSpendingSparkline; // Renamed for clarity
  final List<TimeSeriesDataPoint> recentContributionSparkline; // Added

  const FinancialOverview({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netFlow,
    required this.overallBalance,
    required this.accounts,
    required this.accountBalances,
    required this.activeBudgetsSummary,
    required this.activeGoalsSummary,
    required this.recentSpendingSparkline,
    required this.recentContributionSparkline, // Added
  });

  @override
  List<Object?> get props => [
    totalIncome,
    totalExpenses,
    netFlow,
    overallBalance,
    accounts,
    accountBalances,
    activeBudgetsSummary,
    activeGoalsSummary,
    recentSpendingSparkline,
    recentContributionSparkline, // Added
  ];
}
