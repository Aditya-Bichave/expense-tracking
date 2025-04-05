// lib/features/dashboard/domain/entities/financial_overview.dart
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart'; // ADDED
import 'package:expense_tracker/features/goals/domain/entities/goal.dart'; // ADDED

class FinancialOverview extends Equatable {
  final double totalIncome;
  final double totalExpenses;
  final double netFlow;
  final double overallBalance;
  final List<AssetAccount> accounts;
  final Map<String, double> accountBalances;
  final List<BudgetWithStatus>
      activeBudgetsSummary; // ADDED (e.g., top 3 nearing limit)
  final List<Goal>
      activeGoalsSummary; // ADDED (e.g., top 3 closest to completion)

  const FinancialOverview({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netFlow,
    required this.overallBalance,
    required this.accounts,
    required this.accountBalances,
    required this.activeBudgetsSummary, // ADDED
    required this.activeGoalsSummary, // ADDED
  });

  @override
  List<Object?> get props => [
        totalIncome, totalExpenses, netFlow, overallBalance, accounts,
        accountBalances, activeBudgetsSummary, activeGoalsSummary, // ADDED
      ];
}
