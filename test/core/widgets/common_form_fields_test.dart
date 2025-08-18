import 'package:expense_tracker/core/widgets/common_form_fields.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';

import '../../helpers/pump_app.dart';

class MockCallbacks extends Mock {
  void onTap();
  void onClear();
  void onToggle(int? index);
}

void main() {
  group('CommonFormFields', () {
    late TextEditingController controller;

    setUp(() => controller = TextEditingController());
    tearDown(() => controller.dispose());

    group('buildNameField', () {
      final formKey = GlobalKey<FormState>();
      testWidgets('validator shows error for empty value', (tester) async {
        await pumpWidgetWithProviders(
          tester: tester,
          widget: Builder(
            builder: (context) => Form(
              key: formKey,
              child: CommonFormFields.buildNameField(
                context: context,
                controller: controller,
                labelText: 'Name',
              ),
            ),
          ),
        );
        formKey.currentState!.validate();
        await tester.pump();
        expect(find.text('Please enter a value'), findsOneWidget);
      });

      testWidgets('validator shows error for invalid characters', (
        tester,
      ) async {
        controller.text = 'Invalid@Name';
        await pumpWidgetWithProviders(
          tester: tester,
          widget: Builder(
            builder: (context) => Form(
              key: formKey,
              child: CommonFormFields.buildNameField(
                context: context,
                controller: controller,
                labelText: 'Name',
              ),
            ),
          ),
        );
        formKey.currentState!.validate();
        await tester.pump();
        expect(find.text('Only letters and numbers allowed'), findsOneWidget);
      });
    });

    group('buildAmountField', () {
      final formKey = GlobalKey<FormState>();
      testWidgets('validator shows error for non-positive number', (
        tester,
      ) async {
        controller.text = '0';
        await pumpWidgetWithProviders(
          tester: tester,
          settingsState: const SettingsState(selectedCountryCode: 'US'),
          widget: Builder(
            builder: (context) => Form(
              key: formKey,
              child: CommonFormFields.buildAmountField(
                context: context,
                controller: controller,
                labelText: 'Amount',
                currencySymbol: '\$',
              ),
            ),
          ),
        );
        formKey.currentState!.validate();
        await tester.pump();
        expect(find.text('Must be positive'), findsOneWidget);
      });
    });

    group('buildDatePickerTile', () {
      final mockCallbacks = MockCallbacks();
      testWidgets(
        'shows formatted date and clear button when date is selected',
        (tester) async {
          final date = DateTime(2023, 10, 26);
          await pumpWidgetWithProviders(
            tester: tester,
            widget: Builder(
              builder: (context) => Material(
                child: CommonFormFields.buildDatePickerTile(
                  context: context,
                  selectedDate: date,
                  label: 'Date',
                  onTap: mockCallbacks.onTap,
                  onClear: mockCallbacks.onClear,
                ),
              ),
            ),
          );
          final expected = DateFormatter.formatDate(date);
          expect(find.text(expected), findsOneWidget);
          expect(find.byIcon(Icons.clear), findsOneWidget);

          await tester.tap(find.byIcon(Icons.clear));
          verify(() => mockCallbacks.onClear()).called(1);
        },
      );

      testWidgets('shows "Not Set" when date is null', (tester) async {
        await pumpWidgetWithProviders(
          tester: tester,
          widget: Builder(
            builder: (context) => Material(
              child: CommonFormFields.buildDatePickerTile(
                context: context,
                selectedDate: null,
                label: 'Date',
                onTap: mockCallbacks.onTap,
              ),
            ),
          ),
        );
        expect(find.text('Not Set'), findsOneWidget);
        expect(find.byIcon(Icons.clear), findsNothing);
      });
    });

    group('buildTypeToggle', () {
      final mockCallbacks = MockCallbacks();
      testWidgets('renders labels and calls onToggle', (tester) async {
        await pumpWidgetWithProviders(
          tester: tester,
          widget: Builder(
            builder: (context) => Material(
              child: CommonFormFields.buildTypeToggle(
                context: context,
                initialIndex: 0,
                labels: const ['Expense', 'Income'],
                activeBgColors: const [
                  [Colors.red],
                  [Colors.green],
                ],
                onToggle: mockCallbacks.onToggle,
              ),
            ),
          ),
        );
        expect(find.text('Expense'), findsOneWidget);
        expect(find.text('Income'), findsOneWidget);

        await tester.tap(find.text('Income'));
        await tester.pumpAndSettle();
        verify(() => mockCallbacks.onToggle(1)).called(1);
      });

      testWidgets('is disabled when disabled is true', (tester) async {
        await pumpWidgetWithProviders(
          tester: tester,
          widget: Builder(
            builder: (context) => Material(
              child: CommonFormFields.buildTypeToggle(
                context: context,
                initialIndex: 0,
                labels: const ['Expense', 'Income'],
                activeBgColors: const [
                  [Colors.red],
                  [Colors.green],
                ],
                onToggle: mockCallbacks.onToggle,
                disabled: true,
              ),
            ),
          ),
        );
        final toggleSwitch = tester.widget<ToggleSwitch>(
          find.byType(ToggleSwitch),
        );
        expect(toggleSwitch.onToggle, isNull);
        final ignorePointer = tester.widget<IgnorePointer>(
          find
              .ancestor(
                of: find.byType(ToggleSwitch),
                matching: find.byType(IgnorePointer),
              )
              .first,
        );
        expect(ignorePointer.ignoring, isTrue);
      });
    });
  });
}
