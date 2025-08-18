import 'package:expense_tracker/core/widgets/app_dropdown_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppDropdownFormField', () {
    final dropdownItems = [
      const DropdownMenuItem(value: 'item1', child: Text('Item 1')),
      const DropdownMenuItem(value: 'item2', child: Text('Item 2')),
      const DropdownMenuItem(value: 'item3', child: Text('Item 3')),
    ];

    testWidgets('renders initial value and label text', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Scaffold(
          body: AppDropdownFormField<String>(
            value: 'item1',
            items: dropdownItems,
            onChanged: (_) {},
            labelText: 'My Dropdown',
          ),
        ),
      );

      // ASSERT
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('My Dropdown'), findsOneWidget);
    });

    testWidgets('opens dropdown and shows items on tap', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Scaffold(
          body: AppDropdownFormField<String>(
            key: const ValueKey('my_dropdown'),
            value: 'item1',
            items: dropdownItems,
            onChanged: (_) {},
            labelText: 'My Dropdown',
          ),
        ),
      );

      // ACT
      await tester.tap(find.byKey(const ValueKey('my_dropdown')));
      await tester.pumpAndSettle(); // Wait for animation

      // ASSERT
      expect(find.text('Item 1'), findsWidgets); // The selected item and the item in the list
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('calls onChanged with correct value when item is selected', (tester) async {
      // ARRANGE
      String? selectedValue;
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Scaffold(
          body: AppDropdownFormField<String>(
            value: 'item1',
            items: dropdownItems,
            onChanged: (value) {
              selectedValue = value;
            },
            labelText: 'My Dropdown',
          ),
        ),
      );

      // ACT
      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Item 2').last); // Tap the item in the list
      await tester.pumpAndSettle();

      // ASSERT
      expect(selectedValue, 'item2');
    });

    testWidgets('displays validation error when validator fails', (tester) async {
      // ARRANGE
      final formKey = GlobalKey<FormState>();
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Form(
          key: formKey,
          child: AppDropdownFormField<String>(
            value: null,
            items: dropdownItems,
            onChanged: (_) {},
            labelText: 'My Dropdown',
            validator: (value) => value == null ? 'Cannot be empty' : null,
          ),
        ),
      );

      // ACT
      formKey.currentState!.validate();
      await tester.pump();

      // ASSERT
      expect(find.text('Cannot be empty'), findsOneWidget);
    });

    testWidgets('does not display validation error when validator passes', (tester) async {
      // ARRANGE
      final formKey = GlobalKey<FormState>();
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Form(
          key: formKey,
          child: AppDropdownFormField<String>(
            value: 'item1',
            items: dropdownItems,
            onChanged: (_) {},
            labelText: 'My Dropdown',
            validator: (value) => value == null ? 'Cannot be empty' : null,
          ),
        ),
      );

      // ACT
      formKey.currentState!.validate();
      await tester.pump();

      // ASSERT
      expect(find.text('Cannot be empty'), findsNothing);
    });
  });
}
