import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/budget_summary_widget.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/tokens/app_colors.dart';
import 'package:expense_tracker/ui_kit/tokens/app_typography.dart';
import 'package:expense_tracker/ui_kit/tokens/app_spacing.dart';
import 'package:expense_tracker/ui_kit/tokens/app_radii.dart';
import 'package:expense_tracker/ui_kit/tokens/app_motion.dart';
import 'package:expense_tracker/ui_kit/tokens/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  group('BudgetSummaryWidget Widget Test', () {
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

      // Provide AppKitTheme
      final testTheme = ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        extensions: [
          AppKitTheme(
            colors: AppColors(ColorScheme.fromSeed(seedColor: Colors.blue)),
            typography: AppTypography(Typography.material2021().englishLike),
            spacing: const AppSpacing(),
            radii: const AppRadii(),
            motion: const AppMotion(),
            shadows: const AppShadows(),
          ),
        ],
      );

      await pumpWidgetWithProviders(
        tester: tester,
        theme: testTheme,
        settingsState: const SettingsState(themeMode: ThemeMode.light),
        widget: Scaffold(
          body: BudgetSummaryWidget(
            budgets: budgets,
            recentSpendingData: recentSpendingData,
            disableAnimations: true,
          ),
        ),
      );

      // Verify structure instead of pixels
      expect(find.byType(BudgetSummaryWidget), findsOneWidget);
      // SectionHeader uppercases the title
      expect(find.text('BUDGET STATUS (2)'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
      // Check for spent amounts format (assuming currency is $)
      // Using find.textContaining or exact if formatter allows
      expect(find.textContaining('250'), findsOneWidget);
      expect(find.textContaining('500'), findsOneWidget);
    });
  });
}
