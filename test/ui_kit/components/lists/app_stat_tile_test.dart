import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_stat_tile.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppStatTile', () {
    testWidgets('renders basic stat tile', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppStatTile(label: 'Total Expenses', value: '\$1,234.56'),
      );

      expect(find.text('Total Expenses'), findsOneWidget);
      expect(find.text('\$1,234.56'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppStatTile(
          label: 'Total',
          value: '\$100',
          icon: Icon(Icons.account_balance),
        ),
      );

      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });
  });
}
