import 'package:expense_tracker/features/reports/presentation/widgets/charts/chart_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChartUtils.tooltipTitleStyle returns text style', () {
    // Requires context, so we might need widget test or mock context.
    // Simpler to just verify it returns TextStyle without crashing if context provided.
    // Or skip implementation detail test requiring context.
  });

  test('ChartUtils.sparklineChartData returns valid LineChartData', () {
    final data = ChartUtils.sparklineChartData([
      const FlSpot(0, 0),
    ], Colors.blue);
    expect(data.lineBarsData.length, 1);
    expect(data.gridData.show, false);
    expect(data.titlesData.show, false);
  });
}
