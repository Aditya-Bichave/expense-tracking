import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/widgets/summary_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import '../../../../helpers/pump_app.dart';

class MockSummaryBloc extends MockBloc<SummaryEvent, SummaryState>
    implements SummaryBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late MockSummaryBloc mockSummaryBloc;

  setUp(() {
    mockSummaryBloc = MockSummaryBloc();
    when(() => mockSummaryBloc.state).thenReturn(SummaryInitial());
  });

  testWidgets('SummaryCard renders loading state', (WidgetTester tester) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settle: false, // Don't settle for progress indicator
      blocProviders: [BlocProvider<SummaryBloc>.value(value: mockSummaryBloc)],
      widget: const Scaffold(body: SummaryCard()),
    );
    await tester.pump();

    expect(find.byType(BridgeCircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SummaryCard renders loaded state with categories', (
    WidgetTester tester,
  ) async {
    when(() => mockSummaryBloc.state).thenReturn(
      const SummaryLoaded(
        ExpenseSummary(
          totalExpenses: 500,
          categoryBreakdown: {'Food': 200, 'Transport': 300},
        ),
      ),
    );

    await pumpWidgetWithProviders(
      tester: tester,
      settle: true,
      blocProviders: [BlocProvider<SummaryBloc>.value(value: mockSummaryBloc)],
      widget: const Scaffold(body: SummaryCard()),
    );

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('By Category:'), findsOneWidget);
  });
}
