import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppButton', () {
    testWidgets('renders primary button', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppButton(label: 'Submit', onPressed: () {}),
      );
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('triggers onPressed when tapped', (tester) async {
      bool wasTapped = false;
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppButton(label: 'Tap Me', onPressed: () => wasTapped = true),
      );
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();
      expect(wasTapped, isTrue);
    });

    testWidgets('renders disabled state', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppButton(label: 'Disabled', disabled: true, onPressed: () {}),
      );
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('renders different variants correctly', (tester) async {
      for (final variant in UiVariant.values) {
        await pumpWidgetWithProviders(
          tester: tester,
          widget: AppButton(
            label: variant.name,
            variant: variant,
            onPressed: () {},
          ),
        );
        expect(find.text(variant.name), findsOneWidget);
      }
    });

    testWidgets('renders isLoading state', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        settle:
            false, // Prevents pumpAndSettle timeout due to infinite animation in CircularProgressIndicator
        widget: AppButton(label: 'Loading', isLoading: true, onPressed: () {}),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppButton(
          label: 'With Icon',
          icon: const Icon(Icons.start),
          onPressed: () {},
        ),
      );
      expect(find.byIcon(Icons.start), findsOneWidget);
    });
  });
}
