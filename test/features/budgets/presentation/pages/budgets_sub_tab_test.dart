import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/pages/budgets_sub_tab.dart';
import 'package:expense_tracker/features/budgets/presentation/widgets/budget_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/pump_app.dart';

class MockBudgetListBloc extends MockBloc<BudgetListEvent, BudgetListState>
    implements BudgetListBloc {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late BudgetListBloc mockBloc;
  late MockGoRouter mockGoRouter;

  final mockBudgets = [
    BudgetWithStatus(
      budget: Budget(
        id: '1',
        name: 'Groceries',
        type: BudgetType.overall,
        targetAmount: 500,
        period: BudgetPeriodType.recurringMonthly,
        createdAt: DateTime(2024),
      ),
      amountSpent: 250,
      amountRemaining: 250,
      percentageUsed: 0.5,
      health: BudgetHealth.thriving,
      statusColor: Colors.green,
    ),
  ];

  setUp(() {
    mockBloc = MockBudgetListBloc();
    mockGoRouter = MockGoRouter();
  });

  Widget buildTestWidget() {
    return BlocProvider.value(
      value: mockBloc,
      child: const BudgetsSubTab(),
    );
  }

  group('BudgetsSubTab', () {
    testWidgets('shows loading indicator', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const BudgetListState(status: BudgetListStatus.loading));
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state and handles add button tap', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const BudgetListState(status: BudgetListStatus.success));
      when(() => mockGoRouter.pushNamed(RouteNames.addBudget))
          .thenAnswer((_) async => {});
      await pumpWidgetWithProviders(
          tester: tester, router: mockGoRouter, widget: buildTestWidget());

      expect(find.text('No Budgets Created Yet'), findsOneWidget);
      await tester
          .tap(find.byKey(const ValueKey('button_budgetList_addFirst')));
      verify(() => mockGoRouter.pushNamed(RouteNames.addBudget)).called(1);
    });

    testWidgets('shows error message', (tester) async {
      when(() => mockBloc.state).thenReturn(const BudgetListState(
          status: BudgetListStatus.error, errorMessage: 'Failed'));
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());
      expect(find.text('Error loading budgets: Failed'), findsOneWidget);
    });

    testWidgets('renders a list of BudgetCards', (tester) async {
      when(() => mockBloc.state).thenReturn(BudgetListState(
          status: BudgetListStatus.success, budgetsWithStatus: mockBudgets));
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());
      expect(find.byType(BudgetCard), findsOneWidget);
    });

    testWidgets('tapping FAB navigates to add page', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const BudgetListState(status: BudgetListStatus.success));
      when(() => mockGoRouter.pushNamed(RouteNames.addBudget))
          .thenAnswer((_) async => {});
      await pumpWidgetWithProviders(
          tester: tester, router: mockGoRouter, widget: buildTestWidget());

      await tester.tap(find.byKey(const ValueKey('fab_budgetList_add')));
      verify(() => mockGoRouter.pushNamed(RouteNames.addBudget)).called(1);
    });
  });
}
