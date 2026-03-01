import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:flutter/material.dart';

void main() {
  group('FinancialOverview', () {
    test('props should contain all fields', () {
      final accounts = <AssetAccount>[
        const AssetAccount(
          id: '1',
          name: 'Main',
          type: AssetType.bank,
          initialBalance: 100,
          currentBalance: 100,
        ),
      ];
      final accountBalances = {'1': 100.0};

      final budget = Budget(
        id: 'b1',
        name: 'Groceries',
        type: BudgetType.categorySpecific,
        targetAmount: 500,
        period: BudgetPeriodType.oneTime,
        categoryIds: const ['c1'],
        createdAt: DateTime(2023),
      );

      final activeBudgetsSummary = <BudgetWithStatus>[
        BudgetWithStatus(
          budget: budget,
          amountSpent: 200,
          amountRemaining: 300,
          percentageUsed: 0.4,
          health: BudgetHealth.thriving,
          statusColor: Colors.green,
        ),
      ];

      final activeGoalsSummary = <Goal>[
        Goal(
          id: 'g1',
          name: 'Vacation',
          targetAmount: 1000,
          status: GoalStatus.active,
          totalSaved: 200,
          createdAt: DateTime(2023),
        ),
      ];

      final recentSpendingSparkline = <TimeSeriesDataPoint>[
        TimeSeriesDataPoint(
          date: DateTime(2023),
          amount: const ComparisonValue<double>(currentValue: 50.0),
        ),
      ];

      final recentContributionSparkline = <TimeSeriesDataPoint>[
        TimeSeriesDataPoint(
          date: DateTime(2023),
          amount: const ComparisonValue<double>(currentValue: 20.0),
        ),
      ];

      final overview = FinancialOverview(
        totalIncome: 1000,
        totalExpenses: 500,
        netFlow: 500,
        overallBalance: 1500,
        accounts: accounts,
        accountBalances: accountBalances,
        activeBudgetsSummary: activeBudgetsSummary,
        activeGoalsSummary: activeGoalsSummary,
        recentSpendingSparkline: recentSpendingSparkline,
        recentContributionSparkline: recentContributionSparkline,
      );

      expect(overview.props, [
        1000.0,
        500.0,
        500.0,
        1500.0,
        accounts,
        accountBalances,
        activeBudgetsSummary,
        activeGoalsSummary,
        recentSpendingSparkline,
        recentContributionSparkline,
      ]);
    });

    test('supports value equality', () {
      const overview1 = FinancialOverview(
        totalIncome: 1000,
        totalExpenses: 500,
        netFlow: 500,
        overallBalance: 1500,
        accounts: [],
        accountBalances: {},
        activeBudgetsSummary: [],
        activeGoalsSummary: [],
        recentSpendingSparkline: [],
        recentContributionSparkline: [],
      );

      const overview2 = FinancialOverview(
        totalIncome: 1000,
        totalExpenses: 500,
        netFlow: 500,
        overallBalance: 1500,
        accounts: [],
        accountBalances: {},
        activeBudgetsSummary: [],
        activeGoalsSummary: [],
        recentSpendingSparkline: [],
        recentContributionSparkline: [],
      );

      expect(overview1, equals(overview2));
    });
  });
}
