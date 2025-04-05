// lib/features/goals/data/datasources/goal_contribution_local_data_source.dart
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';

abstract class GoalContributionLocalDataSource {
  Future<List<GoalContributionModel>>
      getAllContributions(); // Needed for recalculation
  Future<List<GoalContributionModel>> getContributionsForGoal(
      String goalId); // Convenience method
  Future<GoalContributionModel?> getContributionById(String id);
  Future<void> saveContribution(
      GoalContributionModel contribution); // Add/Update
  Future<void> deleteContribution(String id);
  Future<void> clearAllContributions();
}
