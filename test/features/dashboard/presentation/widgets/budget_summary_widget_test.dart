import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/budget_summary_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  late MockGoRouter mockGoRouter;

  final mockBudgets = [
    BudgetWithStatus(budget: Budget(id: '1', name: 'Groceries', targetAmount: 500), amountSpent: 250, percentageUsed: 0.5, health: BudgetHealth.healthy),
    BudgetWithStatus(budget: Budget(id: '2', name: 'Entertainment', targetAmount: 200), amountSpent: 100, percentageUsed: 0.5, health: BudgetHealth.healthy),
    BudgetWithStatus(budget: Budget(id: '3', name: 'Utilities', targetAmount: 150), amountSpent: 75, percentageUsed: 0.5, health: BudgetHealth.healthy),
  ];

  setUp(() {
    mockGoRouter = MockGoRouter();
  });

  group('BudgetSummaryWidget', () {
    testWidgets('renders empty state when budgets list is empty', (tester) async {
      when(() => mockGoRouter.pushNamed(RouteNames.addBudget)).thenAnswer((_) async => {});

      await pumpWidgetWithProviders(
        tester: tester,
        router: mockGoRouter,
        widget: const BudgetSummaryWidget(budgets: [], recentSpendingData: []),
      );

      expect(find.text('No active budgets found.'), findsOneWidget);
      final createButton = find.byKey(const ValueKey('button_budgetSummary_create'));
      expect(createButton, findsOneWidget);

      await tester.tap(createButton);
      verify(() => mockGoRouter.pushNamed(RouteNames.addBudget)).called(1);
    });

    testWidgets('renders a list of budgets', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: BudgetSummaryWidget(budgets: [mockBudgets.first], recentSpendingData: []),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.textContaining('Spent:'), findsOneWidget);
    });

    testWidgets('tapping a budget card navigates to detail page', (tester) async {
      when(() => mockGoRouter.pushNamed(
        RouteNames.budgetDetail,
        pathParameters: {'id': '1'},
        extra: any(named: 'extra'),
      )).thenAnswer((_) async => {});

      await pumpWidgetWithProviders(
        tester: tester,
        router: mockGoRouter,
        widget: BudgetSummaryWidget(budgets: [mockBudgets.first], recentSpendingData: []),
      );

      await tester.tap(find.byType(InkWell));

      verify(() => mockGoRouter.pushNamed(
        RouteNames.budgetDetail,
        pathParameters: {'id': '1'},
        extra: mockBudgets.first.budget,
      )).called(1);
    });

    testWidgets('shows "View All" button when there are 3 or more budgets', (tester) async {
      when(() => mockGoRouter.go(RouteNames.budgetsAndCats, extra: any(named: 'extra'))).thenAnswer((_) {});

      await pumpWidgetWithProviders(
        tester: tester,
        router: mockGoRouter,
        widget: BudgetSummaryWidget(budgets: mockBudgets, recentSpendingData: []),
      );

      final viewAllButton = find.byKey(const ValueKey('button_budgetSummary_viewAll'));
      expect(viewAllButton, findsOneWidget);

      await tester.tap(viewAllButton);
      verify(() => mockGoRouter.go(RouteNames.budgetsAndCats, extra: {'initialTabIndex': 0})).called(1);
    });

    testWidgets('hides "View All" button with fewer than 3 budgets', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: BudgetSummaryWidget(budgets: [mockBudgets.first, mockBudgets.last], recentSpendingData: []),
      );

      expect(find.byKey(const ValueKey('button_budgetSummary_viewAll')), findsNothing);
    });
  });
}
