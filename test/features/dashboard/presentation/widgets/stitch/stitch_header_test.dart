import 'package:expense_tracker/features/dashboard/presentation/widgets/stitch/stitch_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  group('StitchHeader', () {
    testWidgets('renders welcome text and user name', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(uiMode: UIMode.stitch),
        widget: const StitchHeader(userName: 'Test User'),
      );

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget); // Profile image
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });
  });
}
