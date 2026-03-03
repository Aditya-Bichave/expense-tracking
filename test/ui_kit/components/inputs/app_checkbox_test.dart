import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_checkbox.dart';

void main() {
  Widget buildTestWidget({
    required bool value,
    required ValueChanged<bool?>? onChanged,
  }) {
    return MaterialApp(
      home: Material(
        child: AppCheckbox(value: value, onChanged: onChanged),
      ),
    );
  }

  group('AppCheckbox', () {
    testWidgets('renders unchecked', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: false, onChanged: (_) {}));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);
    });

    testWidgets('renders checked', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: true, onChanged: (_) {}));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      bool? changedValue;
      await tester.pumpWidget(
        buildTestWidget(value: false, onChanged: (val) => changedValue = val),
      );

      await tester.tap(find.byType(Checkbox));
      expect(changedValue, true);
    });

    testWidgets('renders disabled when onChanged is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: false, onChanged: null));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.onChanged, null);
    });
  });
}
