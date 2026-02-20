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

    expect(find.text('About App'), findsOneWidget);
    expect(find.text('1.2.3'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });
}
