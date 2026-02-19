import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/general_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('GeneralSettingsSection renders correctly', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settingsState: const SettingsState(),
      widget: const Scaffold(
        body: GeneralSettingsSection(state: SettingsState(), isLoading: false),
      ),
    );

    expect(find.text('Manage Categories'), findsOneWidget);
    expect(find.text('Recurring Transactions'), findsOneWidget);
    expect(find.text('Country / Currency'), findsOneWidget);
  });
}
