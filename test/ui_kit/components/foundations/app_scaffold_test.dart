import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppScaffold', () {
    testWidgets('renders basic scaffold correctly', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppScaffold(body: Text('Body Text')),
      );

      // pumpWidgetWithProviders wraps with Scaffold already via GoRouter initial path,
      // so AppScaffold builds a second Scaffold.
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.text('Body Text'), findsOneWidget);
    });

    testWidgets('renders scaffold with AppBar', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppScaffold(
          appBar: AppNavBar(title: 'Nav Title'),
          body: Text('Body Text'),
        ),
      );

      expect(find.text('Nav Title'), findsOneWidget);
      expect(find.text('Body Text'), findsOneWidget);
    });

    testWidgets('renders floating action button and bottom navigation bar', (
      tester,
    ) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppScaffold(
          body: Text('Body Text'),
          floatingActionButton: FloatingActionButton(
            onPressed: null,
            child: Icon(Icons.add),
          ),
          bottomNavigationBar: BottomAppBar(child: Text('Bottom Bar')),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.text('Bottom Bar'), findsOneWidget);
    });
  });
}
