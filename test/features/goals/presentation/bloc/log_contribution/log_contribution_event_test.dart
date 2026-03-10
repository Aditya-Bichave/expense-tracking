import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogContributionEvent', () {
    test('InitializeContribution supports value comparisons', () {
      final date = DateTime(2023, 1, 1);
      final contribution = GoalContribution(
        id: '1',
        goalId: 'g1',
        amount: 10,
        date: date,
        createdAt: date,
      );

      expect(
        const InitializeContribution(goalId: 'g1'),
        equals(const InitializeContribution(goalId: 'g1')),
      );
      expect(
        InitializeContribution(goalId: 'g1', initialContribution: contribution),
        equals(
          InitializeContribution(
            goalId: 'g1',
            initialContribution: contribution,
          ),
        ),
      );
      expect(
        const InitializeContribution(goalId: 'g1'),
        isNot(equals(const InitializeContribution(goalId: 'g2'))),
      );
    });

    test('SaveContribution supports value comparisons', () {
      final date = DateTime(2023, 1, 1);
      expect(
        SaveContribution(amount: 100, date: date, note: 'note'),
        equals(SaveContribution(amount: 100, date: date, note: 'note')),
      );
      expect(
        SaveContribution(amount: 100, date: date, note: 'note'),
        isNot(equals(SaveContribution(amount: 200, date: date, note: 'note'))),
      );
    });

    test('DeleteContribution supports value comparisons', () {
      expect(const DeleteContribution(), equals(const DeleteContribution()));
    });

    test('ClearContributionMessage supports value comparisons', () {
      expect(
        const ClearContributionMessage(),
        equals(const ClearContributionMessage()),
      );
    });
  });
}
