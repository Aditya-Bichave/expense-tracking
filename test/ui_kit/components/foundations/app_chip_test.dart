import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_chip.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppChip', () {
    testWidgets('renders basic chip correctly', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppChip(label: 'Test Chip'),
      );
      expect(find.text('Test Chip'), findsOneWidget);
    });

    testWidgets('renders active chip correctly', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppChip(label: 'Test Chip', isSelected: true),
      );
      expect(find.text('Test Chip'), findsOneWidget);
    });

    testWidgets('triggers onSelected when tapped', (tester) async {
      bool wasTapped = false;
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppChip(label: 'Tap Me', onSelected: () => wasTapped = true),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(wasTapped, isTrue);
    });

    testWidgets('renders icon when provided', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppChip(label: 'With Icon', icon: Icon(Icons.star)),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
    });
  });
}
