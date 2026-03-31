import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';

void main() {
  group('GoalContributionModel Test', () {
    final tDate = DateTime(2023, 1, 1);
    final tCreatedAt = DateTime(2023, 1, 1, 12, 0);

    final tModel = GoalContributionModel(
      id: '1',
      goalId: 'goal_1',
      amount: 100.0,
      date: tDate,
      note: 'Bonus',
      createdAt: tCreatedAt,
    );

    final tEntity = GoalContribution(
      id: '1',
      goalId: 'goal_1',
      amount: 100.0,
      date: tDate,
      note: 'Bonus',
      createdAt: tCreatedAt,
    );

    test('should return a valid model from entity', () {
      // Act
      final result = GoalContributionModel.fromEntity(tEntity);

      // Assert
      expect(result.id, tModel.id);
      expect(result.goalId, tModel.goalId);
      expect(result.amount, tModel.amount);
      expect(result.date, tModel.date);
      expect(result.note, tModel.note);
      expect(result.createdAt, tModel.createdAt);
    });

    test('should return a valid entity from model', () {
      // Act
      final result = tModel.toEntity();

      // Assert
      expect(result, tEntity);
    });
  });
}
