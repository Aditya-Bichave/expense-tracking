import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_search_field.dart';

void main() {
  Widget buildTestWidget({
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    String? hint,
  }) {
    return MaterialApp(
      home: Material(
        child: AppSearchField(
          controller: controller,
          onChanged: onChanged,
          hint: hint,
        ),
      ),
    );
  }

  group('AppSearchField', () {
    testWidgets('renders with default hint text', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders with custom hint text', (tester) async {
      await tester.pumpWidget(buildTestWidget(hint: 'Custom hint'));

      expect(find.text('Custom hint'), findsOneWidget);
    });

    testWidgets('uses provided controller', (tester) async {
      final controller = TextEditingController(text: 'Initial text');
      await tester.pumpWidget(buildTestWidget(controller: controller));

      expect(find.text('Initial text'), findsOneWidget);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      String changedText = '';
      await tester.pumpWidget(
        buildTestWidget(onChanged: (val) => changedText = val),
      );

      await tester.enterText(find.byType(TextField), 'new text');
      expect(changedText, 'new text');
    });
  });
}
