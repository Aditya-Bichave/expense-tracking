import 'package:expense_tracker/features/categories/presentation/widgets/category_appearance_form_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockCallbacks extends Mock {
  void onIconSelected(String iconName);
  void onColorSelected(Color color);
}

void main() {
  late MockCallbacks mockCallbacks;

  setUpAll(() {
    registerFallbackValue(Colors.black);
  });

  setUp(() {
    mockCallbacks = MockCallbacks();
  });

  group('CategoryAppearanceFormSection', () {
    testWidgets('renders selected icon and color', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: CategoryAppearanceFormSection(
            selectedIconName: 'food',
            selectedColor: Colors.green,
            onIconSelected: mockCallbacks.onIconSelected,
            onColorSelected: mockCallbacks.onColorSelected,
          ),
        ),
      );

      expect(find.text('food'), findsOneWidget);
      expect(find.text('#4CAF50'), findsOneWidget); // Hex for Colors.green
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.restaurant_menu_outlined),
      );
      expect(icon.color, Colors.green);
    });

    testWidgets('tapping icon tile shows icon picker', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: Scaffold(
            body: CategoryAppearanceFormSection(
              selectedIconName: 'food',
              selectedColor: Colors.green,
              onIconSelected: mockCallbacks.onIconSelected,
              onColorSelected: mockCallbacks.onColorSelected,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Icon'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Select Icon'), findsOneWidget);
    });

    testWidgets(
      'tapping color tile shows color picker dialog and handles cancellation',
      (tester) async {
        await pumpWidgetWithProviders(
          tester: tester,
          widget: Material(
            child: Scaffold(
              body: CategoryAppearanceFormSection(
                selectedIconName: 'food',
                selectedColor: Colors.blue,
                onIconSelected: mockCallbacks.onIconSelected,
                onColorSelected: mockCallbacks.onColorSelected,
              ),
            ),
          ),
        );

        final colorTileFinder = find.widgetWithText(ListTile, 'Color');
        await tester.tap(colorTileFinder);
        await tester.pumpAndSettle();

        final cancelButton = find.text('Cancel');
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        verifyNever(() => mockCallbacks.onColorSelected(any()));
      },
    );

    testWidgets(
      'tapping color tile shows color picker dialog and handles selection',
      (tester) async {
        await pumpWidgetWithProviders(
          tester: tester,
          widget: Material(
            child: Scaffold(
              body: CategoryAppearanceFormSection(
                selectedIconName: 'food',
                selectedColor: Colors.blue,
                onIconSelected: mockCallbacks.onIconSelected,
                onColorSelected: mockCallbacks.onColorSelected,
              ),
            ),
          ),
        );

        final colorTileFinder = find.widgetWithText(ListTile, 'Color');
        expect(colorTileFinder, findsOneWidget);

        await tester.tap(colorTileFinder);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Pick a color'), findsOneWidget);

        final selectButton = find.text('Select');
        await tester.tap(selectButton);
        await tester.pumpAndSettle();

        verify(() => mockCallbacks.onColorSelected(any())).called(1);
      },
    );
  });
}
