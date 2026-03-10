import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalListEvent', () {
    test('LoadGoals supports value comparisons', () {
      expect(
        const LoadGoals(forceReload: true),
        equals(const LoadGoals(forceReload: true)),
      );
      expect(const LoadGoals(), equals(const LoadGoals(forceReload: false)));
      expect(
        const LoadGoals(forceReload: true),
        isNot(equals(const LoadGoals(forceReload: false))),
      );
    });

    test('ArchiveGoal supports value comparisons', () {
      expect(
        const ArchiveGoal(goalId: '1'),
        equals(const ArchiveGoal(goalId: '1')),
      );
      expect(
        const ArchiveGoal(goalId: '1'),
        isNot(equals(const ArchiveGoal(goalId: '2'))),
      );
    });

    test('DeleteGoal supports value comparisons', () {
      expect(
        const DeleteGoal(goalId: '1'),
        equals(const DeleteGoal(goalId: '1')),
      );
      expect(
        const DeleteGoal(goalId: '1'),
        isNot(equals(const DeleteGoal(goalId: '2'))),
      );
    });

    test('ResetState supports value comparisons', () {
      expect(const ResetState(), equals(const ResetState()));
    });
  });
}
