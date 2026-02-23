import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/pages/budgets_sub_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/pump_app.dart';

class MockBudgetListBloc extends MockBloc<BudgetListEvent, BudgetListState>
    implements BudgetListBloc {}

void main() {
  late MockBudgetListBloc mockBudgetListBloc;

  setUp(() {
    mockBudgetListBloc = MockBudgetListBloc();
  });

  testWidgets('BudgetsSubTab shows empty state', (tester) async {
    when(() => mockBudgetListBloc.state).thenReturn(
      const BudgetListState(
        status: BudgetListStatus.success,
        budgetsWithStatus: [],
      ),
    );

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const BudgetsSubTab(),
      blocProviders: [
        BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
      ],
    );

    expect(find.text('No Budgets Created Yet'), findsOneWidget);
    expect(find.text('Add First Budget'), findsOneWidget);
  });

  testWidgets('BudgetsSubTab shows loading', (tester) async {
    when(() => mockBudgetListBloc.state).thenReturn(
      const BudgetListState(
        status: BudgetListStatus.loading,
        budgetsWithStatus: [],
      ),
    );

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const BudgetsSubTab(),
      blocProviders: [
        BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
      ],
      settle: false,
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
