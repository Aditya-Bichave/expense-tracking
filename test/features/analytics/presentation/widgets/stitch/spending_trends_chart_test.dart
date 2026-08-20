import 'package:expense_tracker/features/analytics/presentation/widgets/stitch/spending_trends_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Mon 2024-01-01 through Sun 2024-01-07.
  List<SpendingTrendPoint> week(List<double> amounts) => [
    for (var i = 0; i < amounts.length; i++)
      SpendingTrendPoint(day: DateTime(2024, 1, 1 + i), amount: amounts[i]),
  ];

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('totals the points it is given', (tester) async {
    await tester.pumpWidget(
      host(SpendingTrendsChart(points: week([100, 200, 50, 25, 25, 0, 50]))),
    );

    expect(find.text('SPENDING TRENDS'), findsOneWidget);
    expect(find.text(r'$450.00'), findsOneWidget);
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  });

  testWidgets('shows a fall against the previous period as trending down', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SpendingTrendsChart(points: week([100, 100]), previousPeriodTotal: 400),
      ),
    );

    // 200 against 400 is a 50% fall.
    expect(find.text('50%'), findsOneWidget);
    expect(find.byIcon(Icons.trending_down), findsOneWidget);
  });

  testWidgets('shows a rise against the previous period as trending up', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(SpendingTrendsChart(points: week([300]), previousPeriodTotal: 200)),
    );

    expect(find.text('50%'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
  });

  testWidgets('omits the delta when there is no usable baseline', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(SpendingTrendsChart(points: week([100]), previousPeriodTotal: 0)),
    );

    // A percentage change from zero is not meaningful, so no badge is shown.
    expect(find.byIcon(Icons.trending_up), findsNothing);
    expect(find.byIcon(Icons.trending_down), findsNothing);
    expect(find.text('vs. previous period'), findsNothing);
  });

  testWidgets('renders an empty state rather than an empty chart', (
    tester,
  ) async {
    await tester.pumpWidget(host(const SpendingTrendsChart(points: [])));

    expect(find.text('No spending in this period'), findsOneWidget);
    expect(find.text(r'$0.00'), findsNothing);
  });

  testWidgets('all-zero amounts do not blow up the scale', (tester) async {
    await tester.pumpWidget(host(SpendingTrendsChart(points: week([0, 0, 0]))));

    expect(tester.takeException(), isNull);
    expect(find.text(r'$0.00'), findsOneWidget);
  });

  testWidgets('repaints when the data changes and not when it is identical', (
    tester,
  ) async {
    // Drives the painter's shouldRepaint/amount-comparison path: same values must
    // not trigger a repaint, different values must.
    await tester.pumpWidget(host(SpendingTrendsChart(points: week([10, 20]))));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(host(SpendingTrendsChart(points: week([10, 20]))));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(host(SpendingTrendsChart(points: week([10, 99]))));
    expect(tester.takeException(), isNull);

    // A different number of points exercises the length short-circuit.
    await tester.pumpWidget(host(SpendingTrendsChart(points: week([10]))));
    expect(tester.takeException(), isNull);
    expect(find.text(r'$10.00'), findsOneWidget);
  });

  testWidgets('a single point renders without dividing by zero', (
    tester,
  ) async {
    await tester.pumpWidget(host(SpendingTrendsChart(points: week([42]))));

    expect(tester.takeException(), isNull);
    expect(find.text(r'$42.00'), findsOneWidget);
  });
}
