import 'package:expense_tracker/features/budgets_cats/presentation/pages/budgets_sub_tab.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockBudgetListBloc mockBudgetListBloc;
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockBudgetListBloc = MockBudgetListBloc();
    mockSettingsBloc = MockSettingsBloc();

    when(() => mockBudgetListBloc.state).thenReturn(const BudgetListState());
    when(
      () => mockBudgetListBloc.stream,
    ).thenAnswer((_) => Stream<BudgetListState>.empty().asBroadcastStream());

    // SettingsBloc stubs removed as they are not used in this test
  });

  testWidgets('BudgetsSubTab renders list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
            BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
          ],
          child: const Scaffold(body: BudgetsSubTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BudgetsSubTab), findsOneWidget);
  });

  testWidgets('BudgetsSubTab pull to refresh triggers timeout handling correctly', (
    tester,
  ) async {
    when(() => mockBudgetListBloc.state).thenReturn(
      const BudgetListState(
        status: BudgetListStatus.success,
        budgetsWithStatus: [],
      ),
    );
    when(
      () => mockBudgetListBloc.stream,
    ).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
            BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
          ],
          child: const Scaffold(body: BudgetsSubTab()),
        ),
      ),
    );
    await tester
        .pump(); // Use pump instead of pumpAndSettle to not wait indefinitely for animations/refresh

    // Wait for the UI to settle (if any animations)
    await tester.pumpAndSettle();

    // Verify RefreshIndicator is present
    final refreshIndicator = find.byType(RefreshIndicator);
    expect(refreshIndicator, findsOneWidget);

    // Get the RefreshIndicator state and call its show() method to trigger onRefresh directly.
    final RefreshIndicatorState state = tester.state(refreshIndicator);
    state.show();

    // Fast-forward past the 3-second timeout duration for firstWhere
    await tester.pump(const Duration(seconds: 4));

    // Wait for the mock list bloc to process the pull to refresh
    await tester.pumpAndSettle();

    // Verify LoadBudgets event was added
    verify(
      () => mockBudgetListBloc.add(const LoadBudgets(forceReload: true)),
    ).called(1);
  });
}
