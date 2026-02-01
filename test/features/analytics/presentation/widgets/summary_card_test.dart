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

  group('SummaryCard', () {
    testWidgets('renders loading indicator when state is SummaryInitial',
        (tester) async {
      when(() => mockSummaryBloc.state).thenReturn(SummaryInitial());

      await pumpWidgetWithProviders(
        tester: tester,
        widget: const SummaryCard(),
        blocProviders: [
          BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
        ],
        settle: false, // Infinite animation
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders loading indicator when state is SummaryLoading',
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

    testWidgets('renders content when state is SummaryLoaded', (tester) async {
      const summary = ExpenseSummary(
        totalExpenses: 123.45,
        categoryBreakdown: {'Food': 100.0, 'Transport': 23.45},
      );
      when(() => mockSummaryBloc.state).thenReturn(SummaryLoaded(summary));

      await pumpWidgetWithProviders(
        tester: tester,
        widget: const SummaryCard(),
        blocProviders: [
          BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
        ],
      );

      expect(find.text('Expense Summary'), findsOneWidget);
      expect(find.text('Total Spent:'), findsOneWidget);
      // Currency formatting depends on settings, defaults to USD '$'
      expect(find.textContaining('123.45'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
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

    testWidgets('renders "No expenses" message when loaded with empty summary',
        (tester) async {
      const summary = ExpenseSummary(
        totalExpenses: 0.0,
        categoryBreakdown: {},
      );
      when(() => mockSummaryBloc.state).thenReturn(SummaryLoaded(summary));

      await pumpWidgetWithProviders(
        tester: tester,
        widget: const SummaryCard(),
        blocProviders: [
          BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
        ],
      );

      expect(find.text('No expenses recorded in the selected period.'),
          findsOneWidget);
    });
  });
}
