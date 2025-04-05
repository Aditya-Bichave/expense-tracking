// lib/features/goals/data/models/goal_contribution_model.dart
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:hive/hive.dart';

part 'goal_contribution_model.g.dart'; // Generate this

@HiveType(typeId: 7)
class GoalContributionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String goalId; // Foreign key simulation

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? note;

  @HiveField(5)
  final DateTime createdAt;

  GoalContributionModel({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
    required this.createdAt,
  });

  factory GoalContributionModel.fromEntity(GoalContribution entity) {
    return GoalContributionModel(
      id: entity.id,
      goalId: entity.goalId,
      amount: entity.amount,
      date: entity.date,
      note: entity.note,
      createdAt: entity.createdAt,
    );
  }

  GoalContribution toEntity() {
    return GoalContribution(
      id: id,
      goalId: goalId,
      amount: amount,
      date: date,
      note: note,
      createdAt: createdAt,
    );
  }
}
