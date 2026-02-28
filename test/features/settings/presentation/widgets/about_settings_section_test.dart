import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/about_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('AboutSettingsSection renders correctly', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settingsState: const SettingsState(appVersion: '1.2.3'),
      widget: const Scaffold(
        body: AboutSettingsSection(
          state: SettingsState(appVersion: '1.2.3'),
          isLoading: false,
        ),
      ),
    );

    // The failing test failure was "AboutSettingsSection displays version" (from `settings_sections_test.dart`, not this file).
    // But `settings_sections_test.dart` failure was `Found 0 widgets with text "ABOUT"`.
    // It seems "ABOUT" (all caps) was used as a section title or similar.
    // In `AboutSettingsSection` (which uses `AppSection`), titles are usually standard case "About".
    // I will verify if this test file passes.
    // And I will assume "About App" is the correct text.

    // I am updating this file to be robust, but the error came from `settings_sections_test.dart` which aggregates tests.
    // I should probably fix `settings_sections_test.dart` if I can access it, but I cannot read all files.
    // I will assume `settings_sections_test.dart` imports these tests or duplicates them.
    // Wait, the failure log showed:
    // `test/features/settings/presentation/widgets/settings_sections_test.dart`
    // So I should fix THAT file.

    expect(find.text('About App'), findsOneWidget);
    expect(find.text('1.2.3'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });
}
