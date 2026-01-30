import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/widgets/summary_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSummaryBloc extends MockBloc<SummaryEvent, SummaryState>
    implements SummaryBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late MockSummaryBloc mockSummaryBloc;
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockSummaryBloc = MockSummaryBloc();
    mockSettingsBloc = MockSettingsBloc();
  });

  Widget pumpWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('SummaryCard shows loading indicator when state is SummaryInitial',
      (tester) async {
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockSummaryBloc.state).thenReturn(SummaryInitial());

    await tester.pumpWidget(pumpWidget(const SummaryCard()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SummaryCard shows loaded data when state is SummaryLoaded',
      (tester) async {
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    const tSummary = ExpenseSummary(
      totalExpenses: 123.45,
      categoryBreakdown: {'Food': 100.0, 'Transport': 23.45},
    );
    when(() => mockSummaryBloc.state).thenReturn(const SummaryLoaded(tSummary));

    await tester.pumpWidget(pumpWidget(const SummaryCard()));
    await tester.pump(); // Allow AnimatedSwitcher to complete

    expect(find.text('Expense Summary'), findsOneWidget);
    expect(find.text('Total Spent:'), findsOneWidget);
    expect(find.textContaining('123.45'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.textContaining('100.00'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
  });

  testWidgets('SummaryCard shows error message when state is SummaryError',
      (tester) async {
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockSummaryBloc.state).thenReturn(const SummaryError('Failed'));

    await tester.pumpWidget(pumpWidget(const SummaryCard()));
    await tester.pump();

    expect(find.text('Error loading summary: Failed'), findsOneWidget);
  });

  testWidgets('SummaryCard shows empty message when no expenses',
      (tester) async {
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    const tSummary = ExpenseSummary(
      totalExpenses: 0,
      categoryBreakdown: {},
    );
    when(() => mockSummaryBloc.state).thenReturn(const SummaryLoaded(tSummary));

    await tester.pumpWidget(pumpWidget(const SummaryCard()));
    await tester.pump();

    expect(find.text('No expenses recorded in the selected period.'),
        findsOneWidget);
  });
}
