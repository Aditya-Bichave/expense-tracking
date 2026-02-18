import 'package:expense_tracker/features/dashboard/presentation/widgets/stitch/stitch_quick_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:mocktail/mocktail.dart'; // Import MockNavigatorObserver if needed

import '../../../../../helpers/pump_app.dart';

void main() {
  group('StitchQuickActions', () {
    testWidgets('renders action buttons', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(uiMode: UIMode.stitch),
        widget: const StitchQuickActions(),
      );

      expect(find.text('QUICK ACTIONS'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Group'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle), findsOneWidget);
    });

    // Interaction tests would require mocking navigation
  });
}
