import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tContribution = GoalContribution(
    id: '1',
    goalId: 'goal1',
    amount: 100.0,
    date: tDate,
    note: 'Test Note',
    createdAt: tDate,
  );

  group('GoalContribution', () {
    test('props should contain all fields', () {
      expect(tContribution.props, [
        '1',
        'goal1',
        100.0,
        tDate,
        'Test Note',
        tDate,
      ]);
    });

    test('supports value equality', () {
      final tContribution2 = GoalContribution(
        id: '1',
        goalId: 'goal1',
        amount: 100.0,
        date: tDate,
        note: 'Test Note',
        createdAt: tDate,
      );
      expect(tContribution, equals(tContribution2));
    });

    test('copyWith should return updated copy', () {
      final updated = tContribution.copyWith(
        amount: 200.0,
        note: 'Updated Note',
      );
      expect(updated.amount, 200.0);
      expect(updated.note, 'Updated Note');
      expect(updated.id, tContribution.id);
    });

    test('copyWith with value getter should allow nulling nullable fields', () {
      final nulled = tContribution.copyWith(noteOrNull: () => null);
      expect(nulled.note, null);
    });
  });
}
