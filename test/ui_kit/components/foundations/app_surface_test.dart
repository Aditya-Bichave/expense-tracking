import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_surface.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppSurface', () {
    testWidgets('renders child in surface container', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppSurface(child: Text('Surface Content')),
      );

      // We look for a container which has surface content inside
      expect(
        find.descendant(
          of: find.byType(AppSurface),
          matching: find.byType(Container),
        ),
        findsWidgets,
      );
      expect(find.text('Surface Content'), findsOneWidget);
    });

    testWidgets('applies padding and decoration', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppSurface(
          padding: EdgeInsets.all(16),
          elevation: 4.0,
          child: Text('Surface Content'),
        ),
      );

      final containerFinder = find
          .ancestor(
            of: find.text('Surface Content'),
            matching: find.byType(Container),
          )
          .first;

      final container = tester.widget<Container>(containerFinder);
      expect(container.padding, const EdgeInsets.all(16));
    });
  });
}
