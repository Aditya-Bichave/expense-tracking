import 'package:expense_tracker/features/dashboard/presentation/widgets/stitch/stitch_goals_list.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  group('StitchGoalsList', () {
    final mockGoals = [
      Goal(
        id: 'g1',
        name: 'New Car',
        targetAmount: 20000,
        totalSaved: 10000,
        status: GoalStatus.active,
        createdAt: DateTime.now(),
      ),
      Goal(
        id: 'g2',
        name: 'Trip',
        targetAmount: 5000,
        totalSaved: 1000,
        status: GoalStatus.active,
        createdAt: DateTime.now(),
      ),
    ];

    testWidgets('renders list of goals', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(uiMode: UIMode.stitch),
        widget: StitchGoalsList(goals: mockGoals),
      );

      expect(find.text('SAVINGS GOALS'), findsOneWidget);
      expect(find.text('New Car'), findsOneWidget);
      expect(find.text('Trip'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget); // 10k/20k
      expect(find.text('20%'), findsOneWidget); // 1k/5k
    });

    testWidgets('renders nothing if empty', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(uiMode: UIMode.stitch),
        widget: const StitchGoalsList(goals: []),
      );

      expect(find.text('SAVINGS GOALS'), findsNothing);
    });
  });
}
