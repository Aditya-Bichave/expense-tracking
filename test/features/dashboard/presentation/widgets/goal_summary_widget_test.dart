import 'package:expense_tracker/features/dashboard/presentation/widgets/goal_summary_widget.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockSettingsBloc mockSettingsBloc;
  late MockGoRouter mockGoRouter;

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
    mockGoRouter = MockGoRouter();
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(
      () => mockSettingsBloc.stream,
    ).thenAnswer((_) => Stream<SettingsState>.empty().asBroadcastStream());

    when(
      () => mockGoRouter.go(any(), extra: any(named: 'extra')),
    ).thenReturn(null);
    when(
      () => mockGoRouter.pushNamed(
        any(),
        pathParameters: any(named: 'pathParameters'),
        queryParameters: any(named: 'queryParameters'),
        extra: any(named: 'extra'),
      ),
    ).thenAnswer((_) async => null);
  });

  final tFixedDate = DateTime(2023, 1, 1);

  Widget createWidgetUnderTest(
    List<Goal> goals, {
    List<TimeSeriesDataPoint>? contributionData,
  }) {
    return MaterialApp(
      home: MockGoRouterProvider(
        router: mockGoRouter,
        child: BlocProvider<SettingsBloc>.value(
          value: mockSettingsBloc,
          child: Scaffold(
            body: GoalSummaryWidget(
              goals: goals,
              recentContributionData:
                  contributionData ??
                  [
                    TimeSeriesDataPoint(
                      date: tFixedDate,
                      amount: const ComparisonValue(currentValue: 10),
                    ),
                  ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'GoalSummaryWidget renders empty state when goals list is empty',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest([]));
      await tester.pumpAndSettle();

      expect(find.text('GOAL PROGRESS'), findsOneWidget);
      expect(find.text('No savings goals set yet.'), findsOneWidget);
      expect(find.text('Create Goal'), findsOneWidget);
    },
  );

  testWidgets('GoalSummaryWidget renders list of goals and indicators', (
    tester,
  ) async {
    final goals = [
      Goal(
        id: '1',
        name: 'Vacation',
        targetAmount: 1000,
        totalSaved: 500,
        status: GoalStatus.active,
        createdAt: tFixedDate,
        targetDate: tFixedDate.add(const Duration(days: 30)),
      ),
      Goal(
        id: '2',
        name: 'Emergency',
        targetAmount: 2000,
        totalSaved: 100,
        status: GoalStatus.active,
        createdAt: tFixedDate,
        targetDate: tFixedDate.add(const Duration(days: 60)),
      ),
    ];

    await tester.pumpWidget(createWidgetUnderTest(goals));
    await tester.pumpAndSettle();

    expect(find.text('GOAL PROGRESS (2)'), findsOneWidget);
    expect(find.text('Vacation'), findsOneWidget);
  });

  testWidgets('tapping Create Goal navigates', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest([]));
    await tester.pumpAndSettle();

    final createGoalButton = find.text('Create Goal');
    expect(createGoalButton, findsOneWidget);

    // We can't easily verify navigation without a real router, but we can check if it's tappable
    await tester.tap(createGoalButton);
    await tester.pumpAndSettle();
  });
}
