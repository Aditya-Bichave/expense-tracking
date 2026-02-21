import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tGoal = Goal(
    id: '1',
    name: 'Test Goal',
    targetAmount: 1000.0,
    targetDate: tDate,
    iconName: 'savings',
    description: 'Test Description',
    status: GoalStatus.active,
    totalSaved: 250.0,
    createdAt: tDate,
  );

  group('Goal', () {
    test('props should contain all fields', () {
      expect(tGoal.props, [
        '1',
        'Test Goal',
        1000.0,
        tDate,
        'savings',
        'Test Description',
        GoalStatus.active,
        250.0,
        tDate,
        null,
      ]);
    });

    test('percentageComplete should calculate correctly', () {
      expect(tGoal.percentageComplete, 0.25);
    });

    test('percentageComplete should be 0 if target is 0', () {
      final zeroGoal = tGoal.copyWith(targetAmount: 0.0);
      expect(zeroGoal.percentageComplete, 0.0);
    });

    test('percentageComplete should be clamped to 1.0', () {
      final overAchievedGoal = tGoal.copyWith(totalSaved: 1500.0);
      expect(overAchievedGoal.percentageComplete, 1.0);
    });

    test('amountRemaining should calculate correctly', () {
      expect(tGoal.amountRemaining, 750.0);
    });

    test('amountRemaining should be 0 if over saved', () {
      final overAchievedGoal = tGoal.copyWith(totalSaved: 1500.0);
      expect(overAchievedGoal.amountRemaining, 0.0);
    });

    test('isAchieved should return true only when status is achieved', () {
      expect(tGoal.isAchieved, false);
      final achievedGoal = tGoal.copyWith(status: GoalStatus.achieved);
      expect(achievedGoal.isAchieved, true);
    });

    test('isArchived should return true only when status is archived', () {
      expect(tGoal.isArchived, false);
      final archivedGoal = tGoal.copyWith(status: GoalStatus.archived);
      expect(archivedGoal.isArchived, true);
    });

    test('displayIconData should return fallback icon if name is null or unknown', () {
      // Assuming 'unknown_icon_name' is not in the map
      final unknownIconGoal = tGoal.copyWith(
        iconName: 'unknown_icon_name',
      );
      expect(unknownIconGoal.displayIconData, Icons.savings_outlined);

      final nullIconGoal = tGoal.copyWith(
        iconNameOrNull: () => null,
      );
      expect(nullIconGoal.displayIconData, Icons.savings_outlined);
    });

    test('copyWith should return updated copy', () {
      final updated = tGoal.copyWith(
        name: 'New Name',
        totalSaved: 500.0,
      );
      expect(updated.name, 'New Name');
      expect(updated.totalSaved, 500.0);
      expect(updated.id, tGoal.id);
    });

     test('copyWith with value getter should allow nulling nullable fields', () {
      final nulled = tGoal.copyWith(
        descriptionOrNull: () => null,
        targetDateOrNull: () => null,
      );
      expect(nulled.description, null);
      expect(nulled.targetDate, null);
    });
  });
}
