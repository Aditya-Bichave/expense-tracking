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
}
