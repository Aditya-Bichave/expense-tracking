import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/spending_bar_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  testWidgets('SpendingBarChart renders correctly with data', (tester) async {
    final tData = [
      CategorySpendingData(
        categoryId: '1',
        categoryName: 'Cat1',
        categoryColor: Colors.red,
        totalAmount: const ComparisonValue(currentValue: 60.0),
        percentage: 0.6,
      ),
      CategorySpendingData(
        categoryId: '2',
        categoryName: 'Cat2',
        categoryColor: Colors.blue,
        totalAmount: const ComparisonValue(currentValue: 40.0),
        percentage: 0.4,
      ),
    ];

    await pumpWidgetWithProviders(
      tester: tester,
      widget: Scaffold(
        body: SpendingBarChart(data: tData),
      ),
    );

    expect(find.byType(BarChart), findsOneWidget);
    // Axis titles are rendered as Text widgets by ChartUtils using sideTitles
    // which eventually uses Text or similar.
    expect(find.text('Cat1'), findsOneWidget);
    expect(find.text('Cat2'), findsOneWidget);
  });

  testWidgets('SpendingBarChart renders empty state when no data', (tester) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: const Scaffold(
        body: SpendingBarChart(data: []),
      ),
    );

    expect(find.byType(BarChart), findsNothing);
    expect(find.text('No data to display'), findsOneWidget);
  });
}
