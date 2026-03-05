import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/charts/app_chart_card.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppChartCard', () {
    testWidgets('renders basic chart card', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppChartCard(
          title: 'Chart Title',
          chart: Text('Chart Content'),
        ),
      );

      expect(find.text('Chart Title'), findsOneWidget);
      expect(find.text('Chart Content'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppChartCard(
          title: 'Chart Title',
          subtitle: 'Chart Subtitle',
          chart: Text('Chart Content'),
        ),
      );

      expect(find.text('Chart Subtitle'), findsOneWidget);
    });

    testWidgets('renders action when provided', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppChartCard(
          title: 'Chart Title',
          action: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
          chart: const Text('Chart Content'),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppChartCard(
          title: 'Chart Title',
          chart: Text('Chart Content'),
          isEmpty: true,
        ),
      );

      expect(find.text('No data available'), findsOneWidget);
      expect(find.text('Chart Content'), findsNothing);
    });
  });
}
