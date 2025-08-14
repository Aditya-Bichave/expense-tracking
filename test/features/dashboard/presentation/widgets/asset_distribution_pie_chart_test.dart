import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_pie_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  test('generateColorMap assigns colors sequentially', () {
    final map = AssetDistributionPieChartState.generateColorMap(
      ['Checking', 'Savings', 'Brokerage'],
    );
    expect(map['Checking'], AssetDistributionPieChartState.colorPalette[0]);
    expect(map['Savings'], AssetDistributionPieChartState.colorPalette[1]);
    expect(map['Brokerage'], AssetDistributionPieChartState.colorPalette[2]);
  });
}
