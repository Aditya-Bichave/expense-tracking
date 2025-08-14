import 'package:expense_tracker/features/goals/presentation/widgets/goal_form.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class FakeSettingsBloc extends Mock implements SettingsBloc {
  @override
  SettingsState get state => const SettingsState();

  @override
  Stream<SettingsState> get stream => Stream.value(state);
}

void main() {
  late FakeSettingsBloc settingsBloc;

  setUp(() {
    settingsBloc = FakeSettingsBloc();
  });

  testWidgets('GoalForm trims name before submit', (tester) async {
    String? submittedName;
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SettingsBloc>.value(
          value: settingsBloc,
          child: Scaffold(
            body: GoalForm(
              onSubmit: (name, amount, date, icon, desc) {
                submittedName = name;
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(AppTextFormField).first, '  My Goal  ');
    await tester.enterText(find.byType(AppTextFormField).at(1), '100');
    await tester.tap(find.text('Add Goal'));
    await tester.pump();
    expect(submittedName, 'My Goal');
  });

  testWidgets('GoalForm rejects whitespace name', (tester) async {
    bool submitted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SettingsBloc>.value(
          value: settingsBloc,
          child: Scaffold(
            body: GoalForm(
              onSubmit: (name, amount, date, icon, desc) {
                submitted = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(AppTextFormField).first, '   ');
    await tester.enterText(find.byType(AppTextFormField).at(1), '100');
    await tester.tap(find.text('Add Goal'));
    await tester.pump();
    expect(submitted, isFalse);
  });
}
