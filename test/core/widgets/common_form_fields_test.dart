// ignore_for_file: directives_ordering

import 'package:expense_tracker/core/widgets/common_form_fields.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'
    hide ValueGetter;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockSettingsBloc extends Mock implements SettingsBloc {}

class FakeSettingsState extends Fake implements SettingsState {}

void main() {
  late MockSettingsBloc mockSettingsBloc;

  setUpAll(() {
    registerFallbackValue(FakeSettingsState());
  });

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
    when(() => mockSettingsBloc.state).thenReturn(FakeSettingsState());
  });

  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: BlocProvider<SettingsBloc>.value(
        value: mockSettingsBloc,
        child: Scaffold(body: child),
      ),
    );
  }

  group('CommonFormFields', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    testWidgets('buildNameField validator shows error for empty value', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          Form(
            autovalidateMode: AutovalidateMode.always,
            child: Builder(
              builder: (context) => CommonFormFields.buildNameField(
                context: context,
                controller: controller,
                labelText: 'Name',
              ),
            ),
          ),
        ),
      );

      // Need a frame for autovalidate to show
      await tester.pump();

      expect(find.text('Please enter a value'), findsOneWidget);
    });

    testWidgets('buildNameField validator shows error for invalid characters', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          Form(
            autovalidateMode: AutovalidateMode.always,
            child: Builder(
              builder: (context) => CommonFormFields.buildNameField(
                context: context,
                controller: controller,
                labelText: 'Name',
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(AppTextFormField), 'Invalid@#\$');
      await tester.pump();

      expect(find.text('Only letters and numbers allowed'), findsOneWidget);
    });

    testWidgets(
      'buildDatePickerTile shows formatted date and clear button when date is selected',
      (tester) async {
        final date = DateTime(2023, 1, 1);

        await tester.pumpWidget(
          createWidgetUnderTest(
            Builder(
              builder: (context) => CommonFormFields.buildDatePickerTile(
                context: context,
                selectedDate: date,
                label: 'Date',
                onTap: () {},
                onClear: () {},
              ),
            ),
          ),
        );

        expect(find.text('1/1/2023'), findsOneWidget);
        expect(find.byIcon(Icons.clear), findsOneWidget);
      },
    );

    testWidgets('buildDatePickerTile shows "Not Set" when date is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          Builder(
            builder: (context) => CommonFormFields.buildDatePickerTile(
              context: context,
              selectedDate: null,
              label: 'Date',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Not Set'), findsOneWidget);
    });

    testWidgets('buildTypeToggle renders labels and calls onToggle', (
      tester,
    ) async {
      int? toggledIndex;
      await tester.pumpWidget(
        createWidgetUnderTest(
          Builder(
            builder: (context) => CommonFormFields.buildTypeToggle(
              context: context,
              initialIndex: 0,
              labels: ['Option A', 'Option B'],
              activeBgColors: [
                [Colors.red],
                [Colors.blue],
              ],
              onToggle: (index) => toggledIndex = index,
            ),
          ),
        ),
      );

      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);

      await tester.tap(find.text('Option B'));
      expect(toggledIndex, 1);
    });

    testWidgets('buildTypeToggle is disabled when disabled is true', (
      tester,
    ) async {
      int? toggledIndex;
      await tester.pumpWidget(
        createWidgetUnderTest(
          Builder(
            builder: (context) => CommonFormFields.buildTypeToggle(
              context: context,
              initialIndex: 0,
              labels: ['Option A', 'Option B'],
              activeBgColors: [
                [Colors.red],
                [Colors.blue],
              ],
              onToggle: (index) => toggledIndex = index,
              disabled: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Option B'), warnIfMissed: false);
      expect(toggledIndex, null);

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.5);
    });
  });
}
