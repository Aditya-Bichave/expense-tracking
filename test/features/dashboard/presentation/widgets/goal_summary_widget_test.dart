import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/goal_summary_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  late MockGoRouter mockGoRouter;

  final mockGoals = [
    Goal(id: '1', name: 'New Car', targetAmount: 20000, totalSaved: 5000),
    Goal(id: '2', name: 'Vacation', targetAmount: 3000, totalSaved: 1500),
    Goal(id: '3', name: 'Laptop', targetAmount: 1500, totalSaved: 750),
  ];

  setUp(() {
    mockGoRouter = MockGoRouter();
  });

  group('GoalSummaryWidget', () {
    testWidgets('renders empty state when goals list is empty', (tester) async {
      when(() => mockGoRouter.pushNamed(RouteNames.addGoal))
          .thenAnswer((_) async => {});

      await pumpWidgetWithProviders(
        tester: tester,
        router: mockGoRouter,
        widget: const GoalSummaryWidget(goals: [], recentContributionData: []),
      );

      expect(find.text('No savings goals set yet.'), findsOneWidget);
      final createButton =
          find.byKey(const ValueKey('button_goalSummary_create'));
      expect(createButton, findsOneWidget);

      await tester.tap(createButton);
      verify(() => mockGoRouter.pushNamed(RouteNames.addGoal)).called(1);
    });

    testWidgets('renders a list of goals', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: GoalSummaryWidget(
            goals: [mockGoals.first], recentContributionData: []),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('New Car'), findsOneWidget);
      expect(find.textContaining('Saved:'), findsOneWidget);
    });

    testWidgets('tapping a goal card navigates to detail page', (tester) async {
      when(() => mockGoRouter.pushNamed(
            RouteNames.goalDetail,
            pathParameters: {'id': '1'},
            extra: any(named: 'extra'),
          )).thenAnswer((_) async => {});

      await pumpWidgetWithProviders(
        tester: tester,
        router: mockGoRouter,
        widget: GoalSummaryWidget(
            goals: [mockGoals.first], recentContributionData: []),
      );

      await tester.tap(find.byType(InkWell));

      verify(() => mockGoRouter.pushNamed(
            RouteNames.goalDetail,
            pathParameters: {'id': '1'},
            extra: mockGoals.first,
          )).called(1);
    });

    testWidgets('shows "View All" button when there are 3 or more goals',
        (tester) async {
      when(() => mockGoRouter.go(RouteNames.budgetsAndCats,
          extra: any(named: 'extra'))).thenAnswer((_) {});

      await pumpWidgetWithProviders(
        tester: tester,
        router: mockGoRouter,
        widget: GoalSummaryWidget(goals: mockGoals, recentContributionData: []),
      );

      final viewAllButton =
          find.byKey(const ValueKey('button_goalSummary_viewAll'));
      expect(viewAllButton, findsOneWidget);

      await tester.tap(viewAllButton);
      verify(() => mockGoRouter.go(RouteNames.budgetsAndCats,
          extra: {'initialTabIndex': 1})).called(1);
    });
  });
}
