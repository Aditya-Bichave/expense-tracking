import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets_cats/presentation/pages/budgets_sub_tab.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bloc_test/bloc_test.dart';
import '../../../../helpers/pump_app.dart';

class MockBudgetListBloc extends MockBloc<BudgetListEvent, BudgetListState>
    implements BudgetListBloc {}

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

void main() {
  late MockBudgetListBloc mockBudgetListBloc;
  late MockCategoryManagementBloc mockCategoryBloc;

  setUp(() {
    mockBudgetListBloc = MockBudgetListBloc();
    mockCategoryBloc = MockCategoryManagementBloc();

    when(() => mockBudgetListBloc.state).thenReturn(const BudgetListState());
    when(
      () => mockBudgetListBloc.stream,
    ).thenAnswer((_) => Stream<BudgetListState>.empty().asBroadcastStream());
    when(
      () => mockCategoryBloc.state,
    ).thenReturn(const CategoryManagementState());
    when(() => mockCategoryBloc.stream).thenAnswer(
      (_) => Stream<CategoryManagementState>.empty().asBroadcastStream(),
    );
  });

  testWidgets('BudgetsSubTab renders list', (tester) async {
    await pumpWidgetWithProviders(
      tester: tester,
      blocProviders: [
        BlocProvider<CategoryManagementBloc>.value(value: mockCategoryBloc),
      ],
      widget: BlocProvider<BudgetListBloc>.value(
        value: mockBudgetListBloc,
        child: const Scaffold(body: BudgetsSubTab()),
      ),
    );

    expect(find.byType(BudgetsSubTab), findsOneWidget);
  });

  testWidgets('pull to refresh stream times out safely', (tester) async {
    when(
      () => mockBudgetListBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockBudgetListBloc.state).thenReturn(
      BudgetListState(
        status: BudgetListStatus.success,
        budgetsWithStatus: [
          BudgetWithStatus(
            budget: Budget(
              id: '1',
              name: 'Food',
              type: BudgetType.categorySpecific,
              targetAmount: 100,
              categoryIds: const ['c1'],
              period: BudgetPeriodType.recurringMonthly,
              createdAt: DateTime.now(),
            ),
            amountSpent: 50,
            amountRemaining: 50,
            percentageUsed: 0.5,
            health: BudgetHealth.thriving,
            statusColor: Colors.green,
          ),
        ],
      ),
    );

    await pumpWidgetWithProviders(
      tester: tester,
      blocProviders: [
        BlocProvider<CategoryManagementBloc>.value(value: mockCategoryBloc),
      ],
      widget: BlocProvider<BudgetListBloc>.value(
        value: mockBudgetListBloc,
        child: const Scaffold(body: BudgetsSubTab()),
      ),
    );

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));

    expect(find.byType(BudgetsSubTab), findsOneWidget);
  });
}
