import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/goal_contribution_chart.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../../test/helpers/pump_app.dart';

void main() {
  testWidgets('GoalContributionChart renders LineChart', (
    WidgetTester tester,
  ) async {
    final contributions = [
      GoalContribution(
        id: '1',
        goalId: '1',
        amount: 100,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ];

    await pumpWidgetWithProviders(
      tester: tester,
      settingsState: const SettingsState(),
      widget: Scaffold(
        body: GoalContributionChart(contributions: contributions),
      ),
    );

    expect(find.byType(LineChart), findsOneWidget);
  });
}
