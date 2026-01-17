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

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
          BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        ],
        child: const Scaffold(
          body: SummaryCard(),
        ),
      ),
    );
  }

  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 123.45,
    categoryBreakdown: {'Food': 100.0, 'Transport': 23.45},
  );

  testWidgets('renders loading indicator when state is SummaryLoading',
      (tester) async {
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockSummaryBloc.state)
        .thenReturn(const SummaryLoading(isReloading: false));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders content when state is SummaryLoaded', (tester) async {
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockSummaryBloc.state)
        .thenReturn(const SummaryLoaded(tExpenseSummary));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Allow AnimatedSwitcher to complete

    expect(find.text('Expense Summary'), findsOneWidget);
    expect(find.text('Total Spent:'), findsOneWidget);
    expect(find.textContaining('123.45'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
  });

  testWidgets('renders error message when state is SummaryError',
      (tester) async {
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockSummaryBloc.state)
        .thenReturn(const SummaryError('Error message'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('Error loading summary'), findsOneWidget);
    expect(find.textContaining('Error message'), findsOneWidget);
  });
}
