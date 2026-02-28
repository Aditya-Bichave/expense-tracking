import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/budget_summary_widget.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

// Correct path: 4 levels up to test/ from test/features/dashboard/presentation/widgets/
import '../../../../helpers/pump_app.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  final tBudget = Budget(
    id: '1',
    name: 'Groceries',
    type: BudgetType.categorySpecific,
    targetAmount: 500,
    period: BudgetPeriodType.recurringMonthly,
    createdAt: DateTime(2023, 1, 1),
  );

  final tBudgetWithStatus = BudgetWithStatus(
    budget: tBudget,
    amountSpent: 250,
    amountRemaining: 250,
    percentageUsed: 0.5,
    health: BudgetHealth.thriving,
    statusColor: Colors.green,
  );

  group('BudgetSummaryWidget Interaction Tests', () {
    testWidgets('renders empty state when no budgets are present', (
      tester,
    ) async {
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(selectedCountryCode: 'US'),
        widget: const BudgetSummaryWidget(budgets: [], recentSpendingData: []),
      );

      expect(find.text('No active budgets found.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('button_budgetSummary_create')),
        findsOneWidget,
      );
    });

    testWidgets('renders budget cards when budgets are present', (
      tester,
    ) async {
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(selectedCountryCode: 'US'),
        widget: BudgetSummaryWidget(
          budgets: [tBudgetWithStatus],
          recentSpendingData: const [],
        ),
      );

      expect(find.text('Groceries'), findsOneWidget);
      // US country code should result in $ symbol via CurrencyFormatter/SettingsState
      expect(find.textContaining('Spent: \$250.00 / \$500.00'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('shows "View All" button when there are 3 or more budgets', (
      tester,
    ) async {
      final manyBudgets = List.generate(
        3,
        (i) => BudgetWithStatus(
          budget: tBudget.copyWith(id: '$i', name: 'Budget $i'),
          amountSpent: 100,
          amountRemaining: 400,
          percentageUsed: 0.2,
          health: BudgetHealth.thriving,
          statusColor: Colors.green,
        ),
      );

      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(selectedCountryCode: 'US'),
        widget: BudgetSummaryWidget(
          budgets: manyBudgets,
          recentSpendingData: const [],
        ),
      );

      expect(
        find.byKey(const ValueKey('button_budgetSummary_viewAll')),
        findsOneWidget,
      );
    });

    testWidgets('hides "View All" button when there are fewer than 3 budgets', (
      tester,
    ) async {
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(selectedCountryCode: 'US'),
        widget: BudgetSummaryWidget(
          budgets: [tBudgetWithStatus, tBudgetWithStatus],
          recentSpendingData: const [],
        ),
      );

      expect(
        find.byKey(const ValueKey('button_budgetSummary_viewAll')),
        findsNothing,
      );
    });
  });
}
