// lib/features/goals/data/datasources/goal_local_data_source_impl.dart
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/main.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveGoalLocalDataSource implements GoalLocalDataSource {
  final Box<GoalModel> goalBox;

  HiveGoalLocalDataSource(this.goalBox);

  @override
  Future<void> clearAllGoals() async {
    try {
      final count = await goalBox.clear();
      log.info("[GoalDS] Cleared goals box ($count items).");
    } catch (e, s) {
      log.severe("[GoalDS] Failed to clear goals cache$e$s");
      throw CacheFailure('Failed to clear goals cache: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      await goalBox.delete(id);
      log.info("[GoalDS] Deleted goal (ID: $id).");
    } catch (e, s) {
      log.severe("[GoalDS] Failed to delete goal (ID: $id)$e$s");
      throw CacheFailure('Failed to delete goal: ${e.toString()}');
    }
  }

  @override
  Future<GoalModel?> getGoalById(String id) async {
    try {
      final goal = goalBox.get(id);
      log.fine(
        goal != null
            ? "[GoalDS] Retrieved goal by ID $id."
            : "[GoalDS] Goal with ID $id not found.",
      );
      return goal;
    } catch (e, s) {
      log.severe("[GoalDS] Failed to get goal by ID $id$e$s");
      throw CacheFailure('Failed to get goal by ID: ${e.toString()}');
    }
  }

  @override
  Future<List<GoalModel>> getGoals() async {
    try {
      final goals = goalBox.values.toList();
      log.info("[GoalDS] Retrieved ${goals.length} goals.");
      return goals;
    } catch (e, s) {
      log.severe("[GoalDS] Failed to get goals$e$s");
      throw CacheFailure('Failed to get goals: ${e.toString()}');
    }
  }

  @override
  Future<void> saveGoal(GoalModel goal) async {
    try {
      await goalBox.put(goal.id, goal);
      log.info("[GoalDS] Saved/Updated goal '${goal.name}' (ID: ${goal.id}).");
    } catch (e, s) {
      log.severe("[GoalDS] Failed to save goal '${goal.name}'$e$s");
      throw CacheFailure('Failed to save goal: ${e.toString()}');
    }
  }
}
