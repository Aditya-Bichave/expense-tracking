import 'package:expense_tracker/features/reports/presentation/bloc/goal_progress_report/goal_progress_report_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalProgressReportEvent', () {
    test('LoadGoalProgressReport supports value comparisons', () {
      expect(
        const LoadGoalProgressReport(),
        equals(const LoadGoalProgressReport()),
      );
    });

    test('ToggleComparison supports value comparisons', () {
      expect(const ToggleComparison(), equals(const ToggleComparison()));
    });
  });
}
