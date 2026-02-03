import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/widgets/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockSummaryBloc extends MockBloc<SummaryEvent, SummaryState>
    implements SummaryBloc {}

void main() {
  late MockSummaryBloc mockSummaryBloc;

  setUp(() {
    mockSummaryBloc = MockSummaryBloc();
  });

  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 150.0,
    categoryBreakdown: {'Food': 100.0, 'Transport': 50.0},
  );

  testWidgets('renders loading indicator when state is SummaryLoading (initial)',
      (tester) async {
    when(() => mockSummaryBloc.state)
        .thenReturn(const SummaryLoading(isReloading: false));

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const SummaryCard(),
      blocProviders: [
        BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
      ],
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders summary content when state is SummaryLoaded',
      (tester) async {
    when(() => mockSummaryBloc.state)
        .thenReturn(const SummaryLoaded(tExpenseSummary));

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const SummaryCard(),
      blocProviders: [
        BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
      ],
    );

    expect(find.text('Expense Summary'), findsOneWidget);
    expect(find.text('Total Spent:'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
  });

  testWidgets('renders previous summary content when reloading',
      (tester) async {
    when(() => mockSummaryBloc.state).thenReturn(const SummaryLoading(
      isReloading: true,
      previousSummary: tExpenseSummary,
    ));

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const SummaryCard(),
      blocProviders: [
        BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
      ],
    );

    expect(find.text('Expense Summary'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets('renders error message when state is SummaryError',
      (tester) async {
    when(() => mockSummaryBloc.state)
        .thenReturn(const SummaryError('Failed to load'));

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const SummaryCard(),
      blocProviders: [
        BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
      ],
    );

    expect(find.text('Error loading summary: Failed to load'), findsOneWidget);
  });
}
