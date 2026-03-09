import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalListState', () {
    test('supports value comparisons', () {
      expect(const GoalListState(), equals(const GoalListState()));
      expect(
        const GoalListState(status: GoalListStatus.loading),
        equals(const GoalListState(status: GoalListStatus.loading)),
      );
      expect(
        const GoalListState(status: GoalListStatus.success),
        isNot(equals(const GoalListState(status: GoalListStatus.error))),
      );
    });

    test('copyWith works correctly', () {
      const state = GoalListState(
        status: GoalListStatus.loading,
        goals: [],
        errorMessage: 'error',
      );

      expect(
        state.copyWith(status: GoalListStatus.success),
        equals(
          const GoalListState(
            status: GoalListStatus.success,
            goals: [],
            errorMessage: 'error',
          ),
        ),
      );

      final goal = Goal(
        id: '1',
        name: 'Vacation',
        targetAmount: 1000,
        totalSaved: 0,
        status: GoalStatus.active,
        createdAt: DateTime(2023, 1, 1),
      );

      expect(
        state.copyWith(goals: [goal]),
        equals(
          GoalListState(
            status: GoalListStatus.loading,
            goals: [goal],
            errorMessage: 'error',
          ),
        ),
      );

      expect(
        state.copyWith(errorMessage: 'new error'),
        equals(
          const GoalListState(
            status: GoalListStatus.loading,
            goals: [],
            errorMessage: 'new error',
          ),
        ),
      );

      expect(
        state.copyWith(clearError: true),
        equals(
          const GoalListState(
            status: GoalListStatus.loading,
            goals: [],
            errorMessage: null,
          ),
        ),
      );
    });
  });
}
