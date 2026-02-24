import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/budget_summary_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class TestMockGoRouter extends Mock implements GoRouter {}

void main() {
  late TestMockGoRouter mockGoRouter;
  final createdAt = DateTime(2023);

  final mockBudgets = [
    BudgetWithStatus(
      budget: Budget(
        id: '1',
        name: 'Groceries',
        targetAmount: 500,
        type: BudgetType.overall,
        period: BudgetPeriodType.recurringMonthly,
        createdAt: createdAt,
      ),
      amountSpent: 250,
      amountRemaining: 250,
      percentageUsed: 0.5,
      health: BudgetHealth.thriving,
    ),
    BudgetWithStatus(
      budget: Budget(
        id: '2',
        name: 'Entertainment',
        targetAmount: 200,
        type: BudgetType.overall,
        period: BudgetPeriodType.recurringMonthly,
        createdAt: createdAt,
      ),
      amountSpent: 100,
      amountRemaining: 100,
      percentageUsed: 0.5,
      health: BudgetHealth.thriving,
    ),
    BudgetWithStatus(
      budget: Budget(
        id: '3',
        name: 'Utilities',
        targetAmount: 150,
        type: BudgetType.overall,
        period: BudgetPeriodType.recurringMonthly,
        createdAt: createdAt,
      ),
      amountSpent: 75,
      amountRemaining: 75,
      percentageUsed: 0.5,
      health: BudgetHealth.thriving,
    ),
  ];

  setUp(() {
    mockGoRouter = TestMockGoRouter();
  });

  void stubRouterToRender(Widget widget) {
    final config = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, __) => widget)],
    );
    when(
      () => mockGoRouter.routeInformationParser,
    ).thenReturn(config.routeInformationParser);
    when(() => mockGoRouter.routerDelegate).thenReturn(config.routerDelegate);
    when(
      () => mockGoRouter.routeInformationProvider,
    ).thenReturn(config.routeInformationProvider);
    when(
      () => mockGoRouter.backButtonDispatcher,
    ).thenReturn(config.backButtonDispatcher);
  }

  group('BudgetSummaryWidget', () {
    testWidgets('renders empty state when budgets list is empty', (
      tester,
    ) async {
      const widget = BudgetSummaryWidget(budgets: [], recentSpendingData: []);
      stubRouterToRender(widget);
      when(
        () => mockGoRouter.pushNamed(RouteNames.addBudget),
      ).thenAnswer((_) async => {});

      await pumpWidgetWithProviders(
        tester: tester,
        router: mockGoRouter,
        widget: widget,
      );

      // UPDATE: Matches the actual text in the widget
      expect(find.text('No active budgets.'), findsOneWidget);
      final createButton = find.byKey(
        const ValueKey('button_budgetSummary_create'),
      );
      expect(createButton, findsOneWidget);

      await tester.tap(createButton);
      verify(() => mockGoRouter.pushNamed(RouteNames.addBudget)).called(1);
    });

    testWidgets('renders a list of budgets', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: BudgetSummaryWidget(
          budgets: [mockBudgets.first],
          recentSpendingData: [],
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.textContaining('Spent:'), findsOneWidget);
    });

    testWidgets('tapping a budget card navigates to detail page', (
      tester,
    ) async {
      final widget = BudgetSummaryWidget(
        budgets: [mockBudgets.first],
        recentSpendingData: [],
      );
      stubRouterToRender(widget);
      when(
        () => mockGoRouter.pushNamed(
          RouteNames.budgetDetail,
          pathParameters: {'id': '1'},
          extra: any(named: 'extra'),
        ),
      ).thenAnswer((_) async => {});

      await pumpWidgetWithProviders(
        tester: tester,
        router: mockGoRouter,
        widget: widget,
      );

      await tester.tap(find.text('Groceries'));

      verify(
        () => mockGoRouter.pushNamed(
          RouteNames.budgetDetail,
          pathParameters: {'id': '1'},
          extra: mockBudgets.first.budget,
        ),
      ).called(1);
    });

    testWidgets('shows "View All" button when there are 3 or more budgets', (
      tester,
    ) async {
      final widget = BudgetSummaryWidget(
        budgets: mockBudgets,
        recentSpendingData: [],
      );
      stubRouterToRender(widget);
      when(
        () => mockGoRouter.go(
          RouteNames.budgetsAndCats,
          extra: any(named: 'extra'),
        ),
      ).thenAnswer((_) {});

      await pumpWidgetWithProviders(
        tester: tester,
        router: mockGoRouter,
        widget: widget,
      );

      final viewAllButton = find.byKey(
        const ValueKey('button_budgetSummary_viewAll'),
      );
      expect(viewAllButton, findsOneWidget);

      await tester.tap(viewAllButton);
      verify(
        () => mockGoRouter.go(
          RouteNames.budgetsAndCats,
          extra: {'initialTabIndex': 0},
        ),
      ).called(1);
    });

    testWidgets('hides "View All" button with fewer than 3 budgets', (
      tester,
    ) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: BudgetSummaryWidget(
          budgets: [mockBudgets.first, mockBudgets.last],
          recentSpendingData: [],
        ),
      );

      expect(
        find.byKey(const ValueKey('button_budgetSummary_viewAll')),
        findsNothing,
      );
    });
  });
}
