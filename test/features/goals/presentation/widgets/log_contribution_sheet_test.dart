import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/core/di/service_configurations/goal_dependencies.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/log_contribution_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late MockLogContributionBloc mockBloc;

  setUpAll(() {
    Testhelpers.registerFallbacks();
    GoalDependencies.register();
  });

  setUp(() {
    mockBloc = MockLogContributionBloc();
  });

  group('LogContributionSheetContent', () {
    testWidgets('renders in "Add" mode and submits', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const LogContributionState(goalId: '1'));
      when(() => mockBloc.add(any())).thenAnswer((_) {});

      await pumpWidgetWithProviders(
        tester: tester,
        logContributionBloc: mockBloc,
        widget: const LogContributionSheetContent(goalId: '1'),
        settle: false,
      );
      await tester.pump();

      expect(find.text('Log Contribution'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount Contributed'), '100');
      await tester
          .tap(find.byKey(const ValueKey('button_submit_contribution')));
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<SaveContribution>()))).called(1);
    });

    testWidgets('shows loading state on button when submitting',
        (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([
          const LogContributionState(
            status: LogContributionStatus.loading,
            goalId: '1',
          )
        ]),
        initialState: const LogContributionState(
          status: LogContributionStatus.loading,
          goalId: '1',
        ),
      );

      await pumpWidgetWithProviders(
        tester: tester,
        logContributionBloc: mockBloc,
        widget: const LogContributionSheetContent(goalId: '1'),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
          find.byKey(const ValueKey('button_submit_contribution')));
      expect(button.onPressed, isNull);
    });
  });
}
