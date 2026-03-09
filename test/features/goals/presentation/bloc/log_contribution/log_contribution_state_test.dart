import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogContributionState', () {
    test('supports value comparisons', () {
      expect(
        const LogContributionState(goalId: '1'),
        equals(const LogContributionState(goalId: '1')),
      );
      expect(
        const LogContributionState(goalId: '1'),
        isNot(equals(const LogContributionState(goalId: '2'))),
      );
    });

    test('initial factory works', () {
      expect(
        LogContributionState.initial('1'),
        equals(const LogContributionState(goalId: '1')),
      );
    });

    test('isEditing returns correct value', () {
      final date = DateTime(2023, 1, 1);
      final contribution = GoalContribution(
        id: '1',
        goalId: '1',
        amount: 10,
        date: date,
        createdAt: date,
      );

      expect(const LogContributionState(goalId: '1').isEditing, isFalse);
      expect(
        LogContributionState(
          goalId: '1',
          initialContribution: contribution,
        ).isEditing,
        isTrue,
      );
    });

    test('copyWith works correctly', () {
      final state = const LogContributionState(
        goalId: '1',
        errorMessage: 'error',
      );

      expect(
        state.copyWith(status: LogContributionStatus.loading),
        equals(
          const LogContributionState(
            goalId: '1',
            status: LogContributionStatus.loading,
            errorMessage: 'error',
          ),
        ),
      );

      final date = DateTime(2023, 1, 1);
      final contribution = GoalContribution(
        id: '1',
        goalId: '1',
        amount: 10,
        date: date,
        createdAt: date,
      );

      expect(
        state.copyWith(initialContribution: contribution),
        equals(
          LogContributionState(
            goalId: '1',
            errorMessage: 'error',
            initialContribution: contribution,
          ),
        ),
      );

      final stateWithContrib = LogContributionState(
        goalId: '1',
        errorMessage: 'error',
        initialContribution: contribution,
      );
      expect(
        stateWithContrib.copyWith(initialContributionOrNull: () => null),
        equals(
          const LogContributionState(
            goalId: '1',
            errorMessage: 'error',
            initialContribution: null,
          ),
        ),
      );

      expect(
        state.copyWith(clearError: true),
        equals(const LogContributionState(goalId: '1', errorMessage: null)),
      );
    });
  });
}
