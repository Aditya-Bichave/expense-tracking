import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/contribution_list_item.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  final mockContribution = GoalContribution(
    id: '1',
    goalId: 'g1',
    amount: 100,
    date: DateTime(2023),
    note: 'Test Note',
    createdAt: DateTime(2023),
  );

  group('ContributionListItem', () {
    testWidgets('renders amount, date, and note', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(selectedCountryCode: 'US'),
        widget: Material(
            child: ContributionListItem(
                contribution: mockContribution, goalId: 'g1')),
      );

      expect(find.text('\$100.00'), findsOneWidget);
      final expectedDate = DateFormatter.formatDate(mockContribution.date);
      expect(find.text(expectedDate), findsOneWidget);
      expect(find.text('Test Note'), findsOneWidget);
    });

    testWidgets('edit button is present', (tester) async {
      // This test mainly just confirms the button exists.
      // Testing that it opens the sheet is better done in the page-level test.
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
            child: ContributionListItem(
                contribution: mockContribution, goalId: 'g1')),
      );

      expect(find.byKey(const ValueKey('button_edit_contribution')),
          findsOneWidget);
    });
  });
}
