import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/income_expense_bar_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  testWidgets('IncomeExpenseBarChart renders correctly with data', (tester) async {
    final tData = [
      IncomeExpensePeriodData(
        periodStart: DateTime(2023, 1, 1),
        totalIncome: const ComparisonValue(currentValue: 1000.0),
        totalExpense: const ComparisonValue(currentValue: 800.0),
      ),
      IncomeExpensePeriodData(
        periodStart: DateTime(2023, 2, 1),
        totalIncome: const ComparisonValue(currentValue: 1200.0),
        totalExpense: const ComparisonValue(currentValue: 900.0),
      ),
    ];

    await pumpWidgetWithProviders(
      tester: tester,
      widget: Scaffold(
        body: IncomeExpenseBarChart(data: tData),
      ),
    );

    expect(find.byType(BarChart), findsOneWidget);
    // Titles are rendered on canvas, so find.text won't work for chart labels in this case.
  });

  testWidgets('IncomeExpenseBarChart renders empty state when no data', (tester) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: const Scaffold(
        body: IncomeExpenseBarChart(data: []),
      ),
    );

    expect(find.byType(BarChart), findsNothing);
    expect(find.text('No data to display'), findsOneWidget);
  });
}
