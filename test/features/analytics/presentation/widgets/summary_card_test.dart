import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/widgets/summary_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSummaryBloc extends MockBloc<SummaryEvent, SummaryState> implements SummaryBloc {}
class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState> implements SettingsBloc {}

void main() {
  late MockSummaryBloc mockSummaryBloc;
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockSummaryBloc = MockSummaryBloc();
    mockSettingsBloc = MockSettingsBloc();
    // Default setting state
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState(
      themeMode: ThemeMode.system,
      selectedCountryCode: 'US',
      isAppLockEnabled: false,
      isInDemoMode: false,
    ));
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<SummaryBloc>.value(value: mockSummaryBloc),
            BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
          ],
          child: const SummaryCard(),
        ),
      ),
    );
  }

  group('SummaryCard', () {
    testWidgets('displays loading indicator when state is SummaryLoading', (tester) async {
      when(() => mockSummaryBloc.state).thenReturn(SummaryLoading(isReloading: false));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when state is SummaryError', (tester) async {
      const errorMessage = 'Something went wrong';
      when(() => mockSummaryBloc.state).thenReturn(const SummaryError(errorMessage));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Error loading summary: $errorMessage'), findsOneWidget);
    });

    testWidgets('displays expense summary when state is SummaryLoaded', (tester) async {
      const summary = ExpenseSummary(
        totalExpenses: 500.0,
        categoryBreakdown: {
          'Food': 300.0,
          'Transport': 200.0,
        },
      );
      when(() => mockSummaryBloc.state).thenReturn(const SummaryLoaded(summary));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Expense Summary'), findsOneWidget);
      expect(find.text('Total Spent:'), findsOneWidget);
      // Assuming format: $500.00
      expect(find.text('\$500.00'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('\$300.00'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('\$200.00'), findsOneWidget);
    });

    testWidgets('displays empty message when summary has no expenses', (tester) async {
      const summary = ExpenseSummary(
        totalExpenses: 0.0,
        categoryBreakdown: {},
      );
      when(() => mockSummaryBloc.state).thenReturn(const SummaryLoaded(summary));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('No expenses recorded in the selected period.'), findsOneWidget);
      expect(find.text('\$0.00'), findsOneWidget);
    });

    // This test is expected to fail if the bug exists
    testWidgets('reloads gracefully without crashing', (tester) async {
       when(() => mockSummaryBloc.state).thenReturn(SummaryLoading(isReloading: true));

       // This will trigger the build method
       await tester.pumpWidget(createWidgetUnderTest());

       // If it crashes, the test fails.
       // If it doesn't crash (e.g. catches exception or handles it), we check what is shown.
       // Given the code, it falls back to "Loading summary data..." if summary is null.
       // But the cast error might happen before.

       // Note: In mocktail, mockSummaryBloc.state returns what we set.
       // The code: context.read<SummaryBloc>().state as SummaryLoaded?
       // This cast will fail because the returned object is SummaryLoading, not SummaryLoaded.
    });
  });
}
