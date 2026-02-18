import 'package:expense_tracker/features/dashboard/presentation/widgets/stitch/stitch_net_balance_card.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  group('StitchNetBalanceCard', () {
    final mockOverview = FinancialOverview(
      totalIncome: 5000,
      totalExpenses: 2000,
      netFlow: 3000,
      overallBalance: 10000,
      accounts: const [],
      accountBalances: const {},
      activeBudgetsSummary: [
        BudgetWithStatus(
          budget: Budget(
            id: 'b1',
            name: 'Groceries',
            type: BudgetType.categorySpecific,
            targetAmount: 1000,
            period: BudgetPeriodType.recurringMonthly,
            createdAt: DateTime.now(),
          ),
          amountSpent: 500,
          amountRemaining: 500,
          percentageUsed: 0.5,
          health: BudgetHealth.thriving,
          statusColor: Colors.green,
        ),
      ],
      activeGoalsSummary: const [],
      recentSpendingSparkline: const [],
      recentContributionSparkline: const [],
    );

    testWidgets('renders balance and stats correctly', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(uiMode: UIMode.stitch),
        widget: StitchNetBalanceCard(overview: mockOverview),
      );

      expect(find.text('NET BALANCE'), findsOneWidget);
      expect(find.text('\$10,000.00'), findsOneWidget); // Balance
      expect(find.text('+\$5,000.00'), findsOneWidget); // Income
      expect(find.text('-\$2,000.00'), findsOneWidget); // Expense
      // Use textContaining because it's inside a RichText with other spans
      expect(find.textContaining('50%'), findsOneWidget); // Budget Progress
    });
  });
}
