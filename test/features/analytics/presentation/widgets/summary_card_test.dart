import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/widgets/summary_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSummaryBloc extends Mock implements SummaryBloc {}

class MockSettingsBloc extends Mock implements SettingsBloc {}

void main() {
  late MockSummaryBloc mockSummaryBloc;
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockSummaryBloc = MockSummaryBloc();
    mockSettingsBloc = MockSettingsBloc();
    when(() => mockSettingsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState(
      selectedCountryCode: 'US',
      themeMode: ThemeMode.system,
      isAppLockEnabled: false,
    ));
    when(() => mockSummaryBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SummaryCard(),
        ),
      ),
    );
  }

  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 150.0,
    categoryBreakdown: {'Food': 100.0, 'Transport': 50.0},
  );

  testWidgets('renders loading state initially', (tester) async {
    when(() => mockSummaryBloc.state)
        .thenReturn(const SummaryLoading(isReloading: false));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders loaded state with data', (tester) async {
    when(() => mockSummaryBloc.state)
        .thenReturn(const SummaryLoaded(tExpenseSummary));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Expense Summary'), findsOneWidget);
    expect(find.text('Total Spent:'), findsOneWidget);
    expect(
        find.textContaining('150.00'), findsOneWidget); // Assuming formatting
    expect(find.text('Food'), findsOneWidget);
    expect(find.textContaining('100.00'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    // There are multiple "50.00" strings (one for Transport, and maybe part of 150.00 if matched partially).
    // We want to ensure we find the one associated with Transport.
    expect(
        find.descendant(
            of: find.widgetWithText(Row, 'Transport'),
            matching: find.textContaining('50.00')),
        findsOneWidget);
  });

  testWidgets('renders loaded state with no expenses', (tester) async {
    const emptySummary = ExpenseSummary(
      totalExpenses: 0.0,
      categoryBreakdown: {},
    );
    when(() => mockSummaryBloc.state)
        .thenReturn(const SummaryLoaded(emptySummary));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Expense Summary'), findsOneWidget);
    expect(find.text('No expenses recorded in the selected period.'),
        findsOneWidget);
  });

  testWidgets('renders loaded state with total expenses but no breakdown',
      (tester) async {
    const summaryNoBreakdown = ExpenseSummary(
      totalExpenses: 100.0,
      categoryBreakdown: {},
    );
    when(() => mockSummaryBloc.state)
        .thenReturn(const SummaryLoaded(summaryNoBreakdown));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Expense Summary'), findsOneWidget);
    expect(
        find.text('No expenses with categories found in the selected period.'),
        findsOneWidget);
  });

  testWidgets('renders error state', (tester) async {
    when(() => mockSummaryBloc.state)
        .thenReturn(const SummaryError('Error message'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Error loading summary: Error message'), findsOneWidget);
  });
}
