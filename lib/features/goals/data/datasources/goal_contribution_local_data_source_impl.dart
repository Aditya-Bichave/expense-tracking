// lib/features/goals/data/datasources/goal_contribution_local_data_source_impl.dart
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/main.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class HiveContributionLocalDataSource
    implements GoalContributionLocalDataSource {
  final Box<GoalContributionModel> contributionBox;

  HiveContributionLocalDataSource(this.contributionBox);

  @override
  Future<void> clearAllContributions() async {
    try {
      final count = await contributionBox.clear();
      log.info("[ContributionDS] Cleared contributions box ($count items).");
    } catch (e, s) {
      log.severe("[ContributionDS] Failed to clear contributions cache$e$s");
      throw CacheFailure(
          'Failed to clear contributions cache: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteContribution(String id) async {
    try {
      await contributionBox.delete(id);
      log.info("[ContributionDS] Deleted contribution (ID: $id).");
    } catch (e, s) {
      log.severe(
          "[ContributionDS] Failed to delete contribution (ID: $id)$e$s");
      throw CacheFailure('Failed to delete contribution: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteContributions(List<String> ids) async {
    try {
      await contributionBox.deleteAll(ids);
      log.info("[ContributionDS] Batch deleted ${ids.length} contributions.");
    } catch (e, s) {
      log.severe(
          "[ContributionDS] Failed to batch delete contributions: ${ids.length} items.$e$s");
      throw CacheFailure(
          'Failed to batch delete contributions: ${e.toString()}');
    }
  }

  @override
  Future<List<GoalContributionModel>> getAllContributions() async {
    try {
      final contributions = contributionBox.values.toList();
      log.fine(
          "[ContributionDS] Retrieved ${contributions.length} total contributions.");
      return contributions;
    } catch (e, s) {
      log.severe("[ContributionDS] Failed to get all contributions$e$s");
      throw CacheFailure('Failed to get all contributions: ${e.toString()}');
    }
  }

  @override
  Future<GoalContributionModel?> getContributionById(String id) async {
    try {
      final contribution = contributionBox.get(id);
      log.fine(contribution != null
          ? "[ContributionDS] Retrieved contribution by ID $id."
          : "[ContributionDS] Contribution with ID $id not found.");
      return contribution;
    } catch (e, s) {
      log.severe("[ContributionDS] Failed to get contribution by ID $id$e$s");
      throw CacheFailure('Failed to get contribution by ID: ${e.toString()}');
    }
  }

  @override
  Future<List<GoalContributionModel>> getContributionsForGoal(
      String goalId) async {
    // In Hive, we have to fetch all and filter manually
    try {
      final all = await getAllContributions();
      final filtered = all.where((c) => c.goalId == goalId).toList();
      log.fine(
          "[ContributionDS] Filtered ${filtered.length} contributions for Goal ID $goalId.");
      return filtered;
    } catch (e, s) {
      log.severe(
          "[ContributionDS] Failed to get contributions for goal $goalId$e$s");
      throw CacheFailure(
          'Failed to get contributions for goal: ${e.toString()}');
    }
  }

  @override
  Future<void> saveContribution(GoalContributionModel contribution) async {
    try {
      await contributionBox.put(contribution.id, contribution);
      log.info(
          "[ContributionDS] Saved/Updated contribution (ID: ${contribution.id}) for Goal ID: ${contribution.goalId}.");
    } catch (e, s) {
      log.severe(
          "[ContributionDS] Failed to save contribution ${contribution.id}$e$s");
      throw CacheFailure('Failed to save contribution: ${e.toString()}');
    }
  }
}
