import 'package:expense_tracker/core/screens/initial_setup_screen.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('InitialSetupScreen renders correctly', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settingsState: const SettingsState(),
      widget: const InitialSetupScreen(),
    );

    expect(find.text('Welcome to Spend Savvy!'), findsOneWidget);
    expect(find.text('Explore Demo Mode'), findsOneWidget);
    expect(find.text('Skip for Now'), findsOneWidget);
  });
}
