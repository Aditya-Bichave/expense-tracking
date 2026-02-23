import 'package:expense_tracker/features/dashboard/presentation/widgets/goal_summary_widget.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsBloc extends Mock implements SettingsBloc {}

void main() {
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockSettingsBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest(List<Goal> goals) {
    return MaterialApp(
      home: BlocProvider<SettingsBloc>.value(
        value: mockSettingsBloc,
        child: Scaffold(
          body: GoalSummaryWidget(
            goals: goals,
            recentContributionData: [
              TimeSeriesDataPoint(
                date: DateTime(2023),
                amount: const ComparisonValue(currentValue: 10),
              ),
            ],
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

  testWidgets('GoalSummaryWidget renders list of goals', (tester) async {
    final goals = [
      Goal(
        id: '1',
        name: 'Vacation',
        targetAmount: 1000,
        totalSaved: 500,
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        targetDate: DateTime.now().add(const Duration(days: 30)),
      ),
    ];

    await tester.pumpWidget(createWidgetUnderTest(goals));
    await tester.pumpAndSettle();

    expect(find.text('GOAL PROGRESS (1)'), findsOneWidget);
    expect(find.text('Vacation'), findsOneWidget);
    expect(find.textContaining('500.00'), findsOneWidget);
  });
}
