import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppTextFormField', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders label and initial value', (tester) async {
      // ARRANGE
      controller.text = 'Initial Text';
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: AppTextFormField(
            controller: controller,
            labelText: 'My Text Field',
          ),
        ),
      );

      // ASSERT
      expect(find.text('My Text Field'), findsOneWidget);
      expect(find.text('Initial Text'), findsOneWidget);
    });

    testWidgets('calls onChanged when text is entered', (tester) async {
      // ARRANGE
      String? changedValue;
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: AppTextFormField(
            key: const ValueKey('my_text_field'),
            controller: controller,
            labelText: 'My Text Field',
            onChanged: (value) => changedValue = value,
          ),
        ),
      );

      // ACT
      await tester.enterText(find.byKey(const ValueKey('my_text_field')), 'New Text');
      await tester.pump();

      // ASSERT
      expect(controller.text, 'New Text');
      expect(changedValue, 'New Text');
    });

    testWidgets('shows clear button when text is present and not readOnly', (tester) async {
      // ARRANGE
      controller.text = 'Some Text';
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: AppTextFormField(
            controller: controller,
            labelText: 'Test',
          ),
        ),
      );

      // ASSERT
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('hides clear button when text is empty', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: AppTextFormField(
            controller: controller,
            labelText: 'Test',
          ),
        ),
      );

      // ASSERT
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('hides clear button when readOnly is true', (tester) async {
      // ARRANGE
      controller.text = 'Some Text';
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: AppTextFormField(
            controller: controller,
            labelText: 'Test',
            readOnly: true,
          ),
        ),
      );

      // ASSERT
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('clear button clears the text in the controller', (tester) async {
      // ARRANGE
      controller.text = 'Some Text';
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: AppTextFormField(
            controller: controller,
            labelText: 'Test',
          ),
        ),
      );
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // ACT
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // ASSERT
      expect(controller.text, isEmpty);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('displays validation error when validator fails', (tester) async {
      // ARRANGE
      final formKey = GlobalKey<FormState>();
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Form(
          key: formKey,
          child: AppTextFormField(
            controller: controller,
            labelText: 'Test',
            validator: (value) => (value?.isEmpty ?? true) ? 'Error!' : null,
          ),
        ),
      );

      // ACT
      formKey.currentState!.validate();
      await tester.pump();

      // ASSERT
      expect(find.text('Error!'), findsOneWidget);
    });

    testWidgets('obeys obscureText property', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: AppTextFormField(
            controller: controller,
            labelText: 'Password',
            obscureText: true,
          ),
        ),
      );

      // ACT
      final textFormField = tester.widget<TextFormField>(find.byType(TextFormField));

      // ASSERT
      expect(textFormField.obscureText, isTrue);
    });
  });
}
