import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/time_series_line_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  testWidgets('TimeSeriesLineChart renders correctly with data', (
    tester,
  ) async {
    final tData = [
      TimeSeriesDataPoint(
        date: DateTime(2023, 1, 1),
        amount: const ComparisonValue(currentValue: 100.0),
      ),
      TimeSeriesDataPoint(
        date: DateTime(2023, 1, 2),
        amount: const ComparisonValue(currentValue: 150.0),
      ),
    ];

    await pumpWidgetWithProviders(
      tester: tester,
      widget: Scaffold(
        body: TimeSeriesLineChart(
          data: tData,
          granularity: TimeSeriesGranularity.daily,
        ),
      ),
    );

    expect(find.byType(LineChart), findsOneWidget);
    // Finding specific dates/labels is complex as fl_chart renders them dynamically.
    // We assume finding LineChart is sufficient validation that the chart widget loaded.
  });

  testWidgets('TimeSeriesLineChart renders empty state when no data', (
    tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: const Scaffold(
        body: TimeSeriesLineChart(
          data: [],
          granularity: TimeSeriesGranularity.daily,
        ),
      ),
    );

    expect(find.byType(LineChart), findsNothing);
    expect(find.text('No data to display'), findsOneWidget);
  });
}
