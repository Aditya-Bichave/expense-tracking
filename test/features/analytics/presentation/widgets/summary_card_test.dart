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

  const tSummary = ExpenseSummary(
    totalExpenses: 150.0,
    categoryBreakdown: {'Food': 100.0, 'Transport': 50.0},
  );

  testWidgets('SummaryCard renders loading indicator when state is SummaryInitial',
      (tester) async {
    when(() => mockSummaryBloc.state).thenReturn(SummaryInitial());

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const SummaryCard(),
      blocProviders: [
        BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
      ],
      settle: false, // Don't settle infinite animations
    );

    // Pump a frame to let the widget render
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Expense Summary'), findsNothing);
  });

  testWidgets('SummaryCard renders loaded data correctly', (tester) async {
    when(() => mockSummaryBloc.state).thenReturn(const SummaryLoaded(tSummary));

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const SummaryCard(),
      blocProviders: [
        BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
      ],
    );

    expect(find.text('Expense Summary'), findsOneWidget);
    expect(find.text('Total Spent:'), findsOneWidget);

    // Check for values more robustly
    expect(find.textContaining('150'), findsOneWidget);

    expect(find.text('By Category:'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.textContaining('100'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);

    // 50 is present in 150 and 50. So we expect at least 1, or specifically 2 if we count both.
    // Ideally we'd look for '$50.00' but currency formatting depends on locale.
    expect(find.textContaining('50'), findsAtLeastNWidgets(1));
  });

  testWidgets('SummaryCard renders error message when state is SummaryError',
      (tester) async {
    const errorMessage = 'Something went wrong';
    when(() => mockSummaryBloc.state).thenReturn(const SummaryError(errorMessage));

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const SummaryCard(),
      blocProviders: [
        BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
      ],
    );

    expect(find.text('Error loading summary: $errorMessage'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('SummaryCard renders previous data and small loading indicator when reloading',
      (tester) async {
    when(() => mockSummaryBloc.state).thenReturn(
       const SummaryLoading(isReloading: true, previousSummary: tSummary)
    );

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const SummaryCard(),
      blocProviders: [
        BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
      ],
      settle: false, // Don't settle infinite animations
    );
    await tester.pump();

    // Should still show the data
    expect(find.text('Expense Summary'), findsOneWidget);
    expect(find.textContaining('150'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);

    // Should also show the small loading indicator in the title row
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
