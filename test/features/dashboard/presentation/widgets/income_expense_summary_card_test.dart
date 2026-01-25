import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/income_expense_summary_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockFinancialOverview extends Mock implements FinancialOverview {}

void main() {
  late MockFinancialOverview mockOverview;

  setUp(() {
    mockOverview = MockFinancialOverview();
  });

  Widget buildTestWidget() {
    return IncomeExpenseSummaryCard(overview: mockOverview);
  }

  group('IncomeExpenseSummaryCard', () {
    testWidgets('renders formatted income and expense amounts', (tester) async {
      when(() => mockOverview.totalIncome).thenReturn(5000.0);
      when(() => mockOverview.totalExpenses).thenReturn(2500.0);

      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(selectedCountryCode: 'US'),
        widget: buildTestWidget(),
      );

      expect(find.text('\$5,000.00'), findsOneWidget);
      expect(find.text('\$2,500.00'), findsOneWidget);
    });

    testWidgets('renders correct colors and icons for income and expenses',
        (tester) async {
      when(() => mockOverview.totalIncome).thenReturn(1.0);
      when(() => mockOverview.totalExpenses).thenReturn(1.0);

      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(selectedCountryCode: 'US'),
        widget: buildTestWidget(),
      );

      final theme =
          Theme.of(tester.element(find.byType(IncomeExpenseSummaryCard)));

      // Find Income Column
      final incomeTitleFinder = find.text('Income');
      final incomeColumnFinder =
          find.ancestor(of: incomeTitleFinder, matching: find.byType(Column));

      final incomeAmountText = tester.widget<Text>(find.descendant(
          of: incomeColumnFinder, matching: find.text('\$1.00')));
      expect(incomeAmountText.style?.color, Colors.green.shade700);

      final incomeIcon = tester.widget<Icon>(find.descendant(
          of: incomeColumnFinder,
          matching: find.byIcon(Icons.arrow_circle_up_outlined)));
      expect(incomeIcon.color, Colors.green.shade700);

      // Find Expenses Column
      final expenseTitleFinder = find.text('Expenses');
      final expenseColumnFinder =
          find.ancestor(of: expenseTitleFinder, matching: find.byType(Column));

      final expenseAmountText = tester.widget<Text>(find.descendant(
          of: expenseColumnFinder, matching: find.text('\$1.00')));
      expect(expenseAmountText.style?.color, theme.colorScheme.error);

      final expenseIcon = tester.widget<Icon>(find.descendant(
          of: expenseColumnFinder,
          matching: find.byIcon(Icons.arrow_circle_down_outlined)));
      expect(expenseIcon.color, theme.colorScheme.error);
    });
  });
}
