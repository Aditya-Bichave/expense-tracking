import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_fab.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppFAB', () {
    testWidgets('renders basic FAB', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppFAB(icon: const Icon(Icons.add), onPressed: () {}),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('triggers onPressed when tapped', (tester) async {
      bool wasTapped = false;
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppFAB(
          icon: const Icon(Icons.add),
          onPressed: () => wasTapped = true,
        ),
      );
      await tester.tap(find.byType(AppFAB));
      await tester.pumpAndSettle();
      expect(wasTapped, isTrue);
    });

    testWidgets('renders disabled state', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppFAB(icon: Icon(Icons.add), onPressed: null),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('renders extended FAB', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppFAB(
          icon: const Icon(Icons.add),
          label: 'Add',
          extended: true,
          onPressed: () {},
        ),
      );
      expect(find.text('Add'), findsOneWidget);
    });
  });
}
