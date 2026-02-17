import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);

  group('GoalModel', () {
    final tGoalModel = GoalModel(
      id: '1',
      name: 'Test Goal',
      targetAmount: 1000.0,
      targetDate: tDate,
      iconName: 'icon',
      description: 'Test description',
      statusIndex: GoalStatus.active.index,
      totalSavedCache: 500.0,
      createdAt: tDate,
      achievedAt: null,
    );

    test('should be a subclass of HiveObject', () {
      expect(tGoalModel, isA<Object>());
    });

    test('fromEntity should return a valid Model', () {
      final tGoal = Goal(
        id: '1',
        name: 'Test Goal',
        targetAmount: 1000.0,
        targetDate: tDate,
        iconName: 'icon',
        description: 'Test description',
        status: GoalStatus.active,
        totalSaved: 500.0,
        createdAt: tDate,
        achievedAt: null,
      );

      final result = GoalModel.fromEntity(tGoal);

      expect(result.id, '1');
      expect(result.name, 'Test Goal');
      expect(result.targetAmount, 1000.0);
      expect(result.targetDate, tDate);
      expect(result.iconName, 'icon');
      expect(result.description, 'Test description');
      expect(result.statusIndex, GoalStatus.active.index);
      expect(result.totalSavedCache, 500.0);
      expect(result.createdAt, tDate);
      expect(result.achievedAt, null);
    });

    test('toEntity should return a valid Entity', () {
      final result = tGoalModel.toEntity();

      expect(result, isA<Goal>());
      expect(result.id, '1');
      expect(result.name, 'Test Goal');
      expect(result.targetAmount, 1000.0);
      expect(result.targetDate, tDate);
      expect(result.iconName, 'icon');
      expect(result.description, 'Test description');
      expect(result.status, GoalStatus.active);
      expect(result.totalSaved, 500.0);
      expect(result.createdAt, tDate);
      expect(result.achievedAt, null);
    });
  });

  group('GoalContributionModel', () {
    final tContributionModel = GoalContributionModel(
      id: '1',
      goalId: 'g1',
      amount: 100.0,
      date: tDate,
      note: 'Test note',
      createdAt: tDate,
    );

    test('should be a subclass of HiveObject', () {
      expect(tContributionModel, isA<Object>());
    });

    test('fromEntity should return a valid Model', () {
      final tContribution = GoalContribution(
        id: '1',
        goalId: 'g1',
        amount: 100.0,
        date: tDate,
        note: 'Test note',
        createdAt: tDate,
      );

      final result = GoalContributionModel.fromEntity(tContribution);

      expect(result.id, '1');
      expect(result.goalId, 'g1');
      expect(result.amount, 100.0);
      expect(result.date, tDate);
      expect(result.note, 'Test note');
      expect(result.createdAt, tDate);
    });

    test('toEntity should return a valid Entity', () {
      final result = tContributionModel.toEntity();

      expect(result, isA<GoalContribution>());
      expect(result.id, '1');
      expect(result.goalId, 'g1');
      expect(result.amount, 100.0);
      expect(result.date, tDate);
      expect(result.note, 'Test note');
      expect(result.createdAt, tDate);
    });
  });
}
