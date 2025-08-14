// lib/features/goals/data/models/goal_model.dart
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:hive/hive.dart';

part 'goal_model.g.dart'; // Generate this

@HiveType(typeId: 6)
class GoalModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double targetAmount;

  @HiveField(3)
  final DateTime? targetDate;

  @HiveField(4)
  final String? iconName;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final int statusIndex; // GoalStatus enum index

  @HiveField(7)
  final double totalSavedCache; // Manually updated cache

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? achievedAt;

  @HiveField(10)
  final bool isNewlyAchieved;

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.targetDate,
    this.iconName,
    this.description,
    required this.statusIndex,
    required this.totalSavedCache,
    required this.createdAt,
    this.achievedAt,
    this.isNewlyAchieved = false,
  });

  factory GoalModel.fromEntity(Goal entity) {
    return GoalModel(
      id: entity.id,
      name: entity.name,
      targetAmount: entity.targetAmount,
      targetDate: entity.targetDate,
      iconName: entity.iconName,
      description: entity.description,
      statusIndex: entity.status.index,
      totalSavedCache: entity.totalSaved,
      createdAt: entity.createdAt,
      achievedAt: entity.achievedAt,
      isNewlyAchieved: entity.isNewlyAchieved,
    );
  }

  Goal toEntity() {
    return Goal(
      id: id,
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
      iconName: iconName,
      description: description,
      status: GoalStatus.values[statusIndex],
      totalSaved: totalSavedCache,
      createdAt: createdAt,
      achievedAt: achievedAt,
      isNewlyAchieved: isNewlyAchieved,
    );
  }
}
