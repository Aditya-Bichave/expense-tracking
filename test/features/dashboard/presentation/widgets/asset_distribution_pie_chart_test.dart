import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_pie_chart.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AssetDistributionPieChart', () {
    testWidgets('renders empty state message when no positive balances exist',
        (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AssetDistributionPieChart(
            accountBalances: {'Bank': 0, 'Cash': -10}),
      );
      expect(find.text('No positive asset balances to chart.'), findsOneWidget);
    });

    testWidgets('renders PieChart and legends when positive balances exist',
        (tester) async {
      final data = {'Bank': 1000.0, 'Stocks': 500.0};
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AssetDistributionPieChart(accountBalances: data),
      );
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('Bank'), findsOneWidget);
      expect(find.text('Stocks'), findsOneWidget);
    });

    testWidgets('renders nothing when UI mode is Quantum', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(uiMode: UIMode.quantum),
        widget:
            const AssetDistributionPieChart(accountBalances: {'Bank': 1000}),
      );
      expect(find.byType(PieChart), findsNothing);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('tapping a chart section updates the touchedIndex',
        (tester) async {
      final data = {'Bank': 1000.0, 'Stocks': 500.0};
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AssetDistributionPieChart(accountBalances: data),
      );

      // Before tap, check the radius of the first section
      var pieChart = tester.widget<PieChart>(find.byType(PieChart));
      var initialRadius =
          (pieChart.data.sections[0] as PieChartSectionData).radius;
      expect(initialRadius, 60.0);

      // Simulate a touch event on the first section (index 0)
      final state = tester.state<AssetDistributionPieChartState>(
          find.byType(AssetDistributionPieChart));
      final touchCallback = pieChart.data.pieTouchData!.touchCallback!;
      final event = FlTapDownEvent(const Offset(0, 0), const Offset(0, 0));
      final response = PieTouchResponse(
        event,
        [PieTouchedSection(pieChart.data.sections[0], 0, 0, 0, 0, 0)],
      );

      // Manually invoke the callback to trigger the setState within the widget
      state.setState(() {
        touchCallback(event, response);
      });
      await tester.pump();

      // After tap, verify the radius has increased
      pieChart = tester.widget<PieChart>(find.byType(PieChart));
      var touchedRadius =
          (pieChart.data.sections[0] as PieChartSectionData).radius;
      expect(touchedRadius, 70.0);
    });
  });

  group('AssetDistributionPieChartState (Unit Tests)', () {
    test('generateColorMap assigns colors correctly and sequentially', () {
      final accounts = ['Bank', 'Cash', 'Stocks'];
      final colorMap =
          AssetDistributionPieChartState.generateColorMap(accounts);

      expect(colorMap.length, 3);
      expect(colorMap['Bank'], AssetDistributionPieChartState.colorPalette[0]);
      expect(colorMap['Cash'], AssetDistributionPieChartState.colorPalette[1]);
      expect(
          colorMap['Stocks'], AssetDistributionPieChartState.colorPalette[2]);
      expect(colorMap['Bank'] != colorMap['Cash'], isTrue);
    });
  });
}
