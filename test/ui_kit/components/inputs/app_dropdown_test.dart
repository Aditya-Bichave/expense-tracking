import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_dropdown.dart';

void main() {
  Widget buildTestWidget({
    String? value,
    List<DropdownMenuItem<String>>? items,
    ValueChanged<String?>? onChanged,
    String? label,
    String? hint,
  }) {
    return MaterialApp(
      home: Material(
        child: AppDropdown<String>(
          value: value,
          items:
              items ??
              [
                const DropdownMenuItem(value: '1', child: Text('Item 1')),
                const DropdownMenuItem(value: '2', child: Text('Item 2')),
              ],
          onChanged: onChanged,
          label: label,
          hint: hint,
        ),
      ),
    );
  }

  group('AppDropdown', () {
    testWidgets('renders hint when no value provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(hint: 'Select an item'));

      expect(find.text('Select an item'), findsOneWidget);
    });

    testWidgets('renders label when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(label: 'My Dropdown'));

      expect(find.text('My Dropdown'), findsOneWidget);
    });

    testWidgets('displays selected value', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: '1'));

      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('calls onChanged when an item is selected', (tester) async {
      String? selectedValue;
      await tester.pumpWidget(
        buildTestWidget(value: '1', onChanged: (val) => selectedValue = val),
      );

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Item 2').last);
      await tester.pumpAndSettle();

      expect(selectedValue, '2');
    });

    testWidgets('is disabled when onChanged is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(onChanged: null));

      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dropdown.onChanged, null);
    });
  });
}
