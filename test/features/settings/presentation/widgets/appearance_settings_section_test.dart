import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/appearance_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/pump_app.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';

void main() {
  testWidgets('AppearanceSettingsSection renders correctly', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settingsState: const SettingsState(),
      widget: const Scaffold(
        body: AppearanceSettingsSection(
          state: SettingsState(),
          isLoading: false,
        ),
      ),
    );

    // It uses AppListTile with Title and Subtitle widgets
    // find.text should work for 'UI Mode' as it is a Text widget
    // If it failed before, maybe it was because of missing imports or context.kit issues (which pumpWidgetWithProviders should handle if App is used, but here we pump directly?)
    // pumpWidgetWithProviders likely sets up Theme/Blocs but maybe not AppKitTheme unless it's in the helper.
    // Assuming helper sets up MaterialApp which contains default Theme.

    // I'll ensure I look for widgets inside AppListTile

    expect(find.byType(AppListTile), findsNWidgets(3));
    expect(find.text('UI Mode'), findsOneWidget);
    expect(find.text('Palette / Variant'), findsOneWidget);
    expect(find.text('Brightness Mode'), findsOneWidget);
  });
}
