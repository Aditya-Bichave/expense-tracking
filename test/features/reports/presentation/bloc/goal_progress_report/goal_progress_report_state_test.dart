import 'package:expense_tracker/features/reports/presentation/bloc/goal_progress_report/goal_progress_report_bloc.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalProgressReportState', () {
    test('GoalProgressReportInitial supports value comparisons', () {
      expect(GoalProgressReportInitial(), equals(GoalProgressReportInitial()));
    });

    test('GoalProgressReportLoading supports value comparisons', () {
      expect(GoalProgressReportLoading(), equals(GoalProgressReportLoading()));
    });

    test('GoalProgressReportLoaded supports value comparisons', () {
      final goal1 = Goal(
        id: '1',
        name: 'G1',
        targetAmount: 100,
        totalSaved: 0,
        status: GoalStatus.active,
        createdAt: DateTime(2023, 1, 1),
      );
      final dataPoint = GoalProgressData(goal: goal1, contributions: []);
      final reportData1 = GoalProgressReportData(progressData: [dataPoint]);
      final reportData2 = GoalProgressReportData(progressData: [dataPoint]);
      const reportData3 = GoalProgressReportData(progressData: []);

      expect(
        GoalProgressReportLoaded(reportData1),
        equals(GoalProgressReportLoaded(reportData2)),
      );
      expect(
        GoalProgressReportLoaded(reportData1),
        isNot(equals(GoalProgressReportLoaded(reportData3))),
      );
      expect(
        GoalProgressReportLoaded(reportData1, isComparisonEnabled: true),
        isNot(
          equals(
            GoalProgressReportLoaded(reportData1, isComparisonEnabled: false),
          ),
        ),
      );
    });

    test('GoalProgressReportError supports value comparisons', () {
      expect(
        const GoalProgressReportError('error'),
        equals(const GoalProgressReportError('error')),
      );
      expect(
        const GoalProgressReportError('error'),
        isNot(equals(const GoalProgressReportError('error2'))),
      );
    });
  });
}
