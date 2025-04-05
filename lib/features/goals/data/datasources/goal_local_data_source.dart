// lib/features/goals/data/datasources/goal_local_data_source.dart
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';

abstract class GoalLocalDataSource {
  Future<List<GoalModel>> getGoals();
  Future<GoalModel?> getGoalById(String id);
  Future<void> saveGoal(GoalModel goal); // Add/Update
  Future<void> deleteGoal(String id);
  Future<void> clearAllGoals();
}
