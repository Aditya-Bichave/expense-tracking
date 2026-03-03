import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';

void main() {
  Widget buildTestWidget({
    TextEditingController? controller,
    String? label,
    String? hint,
    String? errorText,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    return MaterialApp(
      home: Material(
        child: AppTextField(
          controller: controller,
          label: label,
          hint: hint,
          errorText: errorText,
          enabled: enabled,
          onChanged: onChanged,
        ),
      ),
    );
  }

  group('AppTextField', () {
    testWidgets('renders hint only when no label provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(hint: 'Test hint'));

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Test hint'), findsOneWidget);
    });

    testWidgets('renders label when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(label: 'Test label'));

      expect(find.text('Test label'), findsOneWidget);
    });

    testWidgets('renders error text when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(errorText: 'Error!'));

      expect(find.text('Error!'), findsOneWidget);
    });

    testWidgets('handles user input and controller', (tester) async {
      final controller = TextEditingController();
      String changedText = '';

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          onChanged: (val) => changedText = val,
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Hello');
      expect(changedText, 'Hello');
      expect(controller.text, 'Hello');
    });

    testWidgets('respects enabled flag', (tester) async {
      await tester.pumpWidget(buildTestWidget(enabled: false));

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(textField.enabled, false);
    });
  });
}
