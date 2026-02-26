import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTextFormField', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    testWidgets('renders label and initial value', (tester) async {
      controller.text = 'Initial';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextFormField(
              controller: controller,
              labelText: 'My Label',
            ),
          ),
        ),
      );

      expect(find.text('My Label'), findsOneWidget);
      expect(find.text('Initial'), findsOneWidget);
    });

    testWidgets('shows clear button when text is present and not readOnly', (
      tester,
    ) async {
      controller.text = 'Text';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextFormField(controller: controller, labelText: 'Label'),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('hides clear button when text is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextFormField(controller: controller, labelText: 'Label'),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('hides clear button when readOnly is true', (tester) async {
      controller.text = 'Text';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextFormField(
              controller: controller,
              labelText: 'Label',
              readOnly: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('clear button clears the text in the controller', (
      tester,
    ) async {
      controller.text = 'Text';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextFormField(controller: controller, labelText: 'Label'),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump(); // Rebuild

      expect(controller.text, isEmpty);
      expect(find.text('Text'), findsNothing);
    });

    testWidgets('calls onChanged when text is entered', (tester) async {
      String changedText = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextFormField(
              controller: controller,
              labelText: 'Label',
              onChanged: (val) => changedText = val,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'New');
      expect(changedText, 'New');
    });

    testWidgets('displays validation error when validator fails', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: AppTextFormField(
                controller: controller,
                labelText: 'Label',
                validator: (val) => 'Error occurred',
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Error occurred'), findsOneWidget);
    });

    testWidgets('renders asterisk when isRequired is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextFormField(
              controller: controller,
              labelText: 'Label',
              isRequired: true,
            ),
          ),
        ),
      );

      final richTextFinder = find.byWidgetPredicate((widget) {
        if (widget is Text && widget.textSpan != null) {
          final span = widget.textSpan!;
          return span.toPlainText().contains(' *');
        }
        return false;
      });

      expect(richTextFinder, findsOneWidget);
    });

    testWidgets('obeys obscureText property', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextFormField(
              controller: controller,
              labelText: 'Label',
              obscureText: true,
            ),
          ),
        ),
      );

      // Verify TextField inside TextFormField has obscureText = true
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, true);
    });
  });
}
