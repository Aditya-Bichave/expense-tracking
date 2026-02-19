import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/data_management_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('DataManagementSettingsSection renders tiles', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settingsState: const SettingsState(),
      widget: Scaffold(
        body: DataManagementSettingsSection(
          isDataManagementLoading: false,
          isSettingsLoading: false,
          onBackup: () {},
          onRestore: () {},
          onClearData: () {},
        ),
      ),
    );

    // SectionHeader uppercases the title
    expect(find.text('DATA MANAGEMENT'), findsOneWidget);
    expect(find.text('Backup Data'), findsOneWidget);
    expect(find.text('Restore Data'), findsOneWidget);
    expect(find.text('Clear All Data'), findsOneWidget);
  });

  testWidgets('DataManagementSettingsSection triggers callbacks', (
    WidgetTester tester,
  ) async {
    bool backupCalled = false;
    bool restoreCalled = false;
    bool clearCalled = false;

    await pumpWidgetWithProviders(
      tester: tester,
      settingsState: const SettingsState(),
      widget: Scaffold(
        body: DataManagementSettingsSection(
          isDataManagementLoading: false,
          isSettingsLoading: false,
          onBackup: () => backupCalled = true,
          onRestore: () => restoreCalled = true,
          onClearData: () => clearCalled = true,
        ),
      ),
    );

    await tester.tap(find.text('Backup Data'));
    expect(backupCalled, isTrue);

    await tester.tap(find.text('Restore Data'));
    expect(restoreCalled, isTrue);

    await tester.tap(find.text('Clear All Data'));
    expect(clearCalled, isTrue);
  });
}
