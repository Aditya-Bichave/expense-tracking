import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/log_contribution_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockLogContributionBloc extends MockBloc<LogContributionEvent, LogContributionState>
    implements LogContributionBloc {}

void main() {
  late LogContributionBloc mockBloc;

  setUp(() {
    mockBloc = MockLogContributionBloc();
    sl.registerFactory<LogContributionBloc>(() => mockBloc);
  });

  tearDown(() {
    sl.reset();
  });

  group('LogContributionSheetContent', () {
    testWidgets('renders in "Add" mode and submits', (tester) async {
      when(() => mockBloc.state).thenReturn(const LogContributionState());
      when(() => mockBloc.add(any())).thenAnswer((_) {});

      await pumpWidgetWithProviders(
        tester: tester,
        widget: const LogContributionSheetContent(),
      );

      expect(find.text('Log Contribution'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Amount Contributed'), '100');
      await tester.tap(find.byKey(const ValueKey('button_submit_contribution')));
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<SaveContribution>()))).called(1);
    });

    testWidgets('shows loading state on button when submitting', (tester) async {
      when(() => mockBloc.state).thenReturn(const LogContributionState(status: LogContributionStatus.loading));

      await pumpWidgetWithProviders(
        tester: tester,
        widget: const LogContributionSheetContent(),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
