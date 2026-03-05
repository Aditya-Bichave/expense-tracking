import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_icon_button.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppIconButton', () {
    testWidgets('renders basic icon button', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppIconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {},
        ),
      );
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('triggers onPressed when tapped', (tester) async {
      bool wasTapped = false;
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppIconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => wasTapped = true,
        ),
      );
      await tester.tap(find.byType(AppIconButton));
      await tester.pumpAndSettle();
      expect(wasTapped, isTrue);
    });

    testWidgets('renders disabled state', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppIconButton(
          icon: Icon(Icons.settings),
          onPressed: null,
        ),
      );
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
