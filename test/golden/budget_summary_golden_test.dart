import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/budget_summary_widget.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  group('BudgetSummaryWidget Golden Test', () {
    testWidgets('renders correctly with budgets', (tester) async {
      final budgets = [
        BudgetWithStatus(
          budget: Budget(
            id: '1',
            name: 'Groceries',
            type: BudgetType.categorySpecific,
            targetAmount: 500,
            period: BudgetPeriodType.recurringMonthly,
            createdAt: DateTime(2023, 1, 1),
          ),
          amountSpent: 250,
          amountRemaining: 250,
          percentageUsed: 0.5,
          health: BudgetHealth.thriving,
          statusColor: Colors.green,
        ),
        BudgetWithStatus(
          budget: Budget(
            id: '2',
            name: 'Entertainment',
            type: BudgetType.categorySpecific,
            targetAmount: 200,
            period: BudgetPeriodType.recurringMonthly,
            createdAt: DateTime(2023, 1, 1),
          ),
          amountSpent: 190,
          amountRemaining: 10,
          percentageUsed: 0.95,
          health: BudgetHealth.nearingLimit,
          statusColor: Colors.orange,
        ),
      ];

      final recentSpendingData = [
        TimeSeriesDataPoint(
          date: DateTime(2023, 10, 1),
          amount: const ComparisonValue(currentValue: 50.0),
        ),
        TimeSeriesDataPoint(
          date: DateTime(2023, 10, 2),
          amount: const ComparisonValue(currentValue: 100.0),
        ),
        TimeSeriesDataPoint(
          date: DateTime(2023, 10, 3),
          amount: const ComparisonValue(currentValue: 75.0),
        ),
      ];

      // Set a fixed surface size for deterministic golden tests
      await tester.binding.setSurfaceSize(const Size(400, 800));

      // Use a basic theme to avoid Google Fonts network issues in CI
      final testTheme = ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      );

      await pumpWidgetWithProviders(
        tester: tester,
        theme: testTheme, darkTheme: testTheme,
        settingsState: const SettingsState(themeMode: ThemeMode.light),
        widget: Scaffold(
          body: BudgetSummaryWidget(
            budgets: budgets,
            recentSpendingData: recentSpendingData,
          ),
        ),
      );

      await expectLater(
        find.byType(BudgetSummaryWidget),
        matchesGoldenFile('goldens/budget_summary_widget.png'),
      );
    });
  });
}
