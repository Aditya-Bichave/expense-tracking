import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/income_expense_summary_card.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/overall_balance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets(
    'DashboardHeader renders OverallBalanceCard and IncomeExpenseSummaryCard',
    (tester) async {
      const overview = FinancialOverview(
        totalIncome: 5000.0,
        totalExpenses: 2000.0,
        netFlow: 3000.0,
        overallBalance: 10000.0,
        accounts: [],
        accountBalances: {},
        activeBudgetsSummary: [],
        activeGoalsSummary: [],
        recentSpendingSparkline: [],
        recentContributionSparkline: [],
      );

      await pumpWidgetWithProviders(
        tester: tester,
        widget: const Scaffold(body: DashboardHeader(overview: overview)),
      );

      expect(find.byType(OverallBalanceCard), findsOneWidget);
      expect(find.byType(IncomeExpenseSummaryCard), findsOneWidget);

      // Check values rendered in children
      expect(find.text('\$10,000.00'), findsOneWidget); // Overall Balance
      expect(find.text('\$5,000.00'), findsOneWidget); // Income
      expect(find.text('\$2,000.00'), findsOneWidget); // Expenses
      // Net Flow: "Net Flow (Period): " and amount
      expect(find.text('\$3,000.00'), findsOneWidget);
    },
  );
}
