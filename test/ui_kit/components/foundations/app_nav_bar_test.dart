import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppNavBar', () {
    testWidgets('renders title', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const Scaffold(
          appBar: AppNavBar(title: 'Test Title'),
          body: Center(child: Text('Body')),
        ),
      );
      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('renders leading and actions', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const Scaffold(
          appBar: AppNavBar(
            title: 'Title',
            leading: Icon(Icons.arrow_back),
            actions: [Icon(Icons.settings)],
          ),
          body: Center(child: Text('Body')),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders custom title widget', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const Scaffold(
          appBar: AppNavBar(titleWidget: Text('Custom Title')),
          body: Center(child: Text('Body')),
        ),
      );

      expect(find.text('Custom Title'), findsOneWidget);
    });
  });
}
