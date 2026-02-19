import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/security_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('SecuritySettingsSection renders correctly', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settingsState: const SettingsState(),
      widget: Scaffold(
        body: SecuritySettingsSection(
          state: const SettingsState(isAppLockEnabled: true),
          isLoading: false,
          onAppLockToggle: (context, value) {},
        ),
      ),
    );

    expect(find.byType(SwitchListTile), findsOneWidget);
    final switchTile = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switchTile.value, isTrue);
  });

  testWidgets('SecuritySettingsSection toggles switch', (
    WidgetTester tester,
  ) async {
    bool toggled = false;
    await pumpWidgetWithProviders(
      tester: tester,
      settingsState: const SettingsState(),
      widget: Scaffold(
        body: SecuritySettingsSection(
          state: const SettingsState(isAppLockEnabled: false),
          isLoading: false,
          onAppLockToggle: (context, value) {
            toggled = true;
          },
        ),
      ),
    );

    await tester.tap(find.byType(SwitchListTile));
    expect(toggled, isTrue);
  });
}
