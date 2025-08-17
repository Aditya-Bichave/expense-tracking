import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('IconPickerDialogContent', () {
    testWidgets('renders grid of icons', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: IconPickerDialogContent(currentIconName: 'food')),
      ));

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu_outlined), findsOneWidget);
    });

    testWidgets('filters icons based on search query', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: IconPickerDialogContent(currentIconName: 'food')),
      ));

      await tester.enterText(find.byType(TextField), 'salary');
      await tester.pump();

      expect(find.byIcon(Icons.work_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu_outlined), findsNothing);
    });

    testWidgets('tapping an icon selects it', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: IconPickerDialogContent(currentIconName: 'food')),
      ));

      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pump();

      final container = tester.widget<Container>(find
          .ancestor(
            of: find.byIcon(Icons.shopping_cart_outlined),
            matching: find.byType(Container),
          )
          .first);

      final border = container.decoration as BoxDecoration;
      expect(border.border, isNotNull);
      expect(border.border!.isUniform, isTrue);
    });

    testWidgets('tapping Select button pops with selected icon',
        (tester) async {
      String? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showIconPicker(context, 'food');
              },
              child: const Text('Show'),
            ),
          );
        }),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(IconPickerDialogContent), findsOneWidget);

      await tester.tap(find.byIcon(Icons.credit_card_outlined));
      await tester.tap(find.byKey(const ValueKey('button_select')));
      await tester.pumpAndSettle();

      expect(result, 'credit_card');
    });
  });
}
