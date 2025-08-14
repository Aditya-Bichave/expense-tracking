// lib/features/goals/data/repositories/goal_contribution_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart'; // Needed to update Goal cache
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/main.dart';

class GoalContributionRepositoryImpl implements GoalContributionRepository {
  final GoalContributionLocalDataSource contributionDataSource;
  final GoalLocalDataSource goalDataSource; // Inject Goal DS

  GoalContributionRepositoryImpl({
    required this.contributionDataSource,
    required this.goalDataSource, // Modified constructor
  });

  // --- Crucial Helper to Recalculate and Cache ---
  Future<Either<Failure, void>> _updateGoalTotalSavedCache(
    String goalId,
  ) async {
    log.fine(
      "[ContributionRepo] Updating totalSaved cache for Goal ID: $goalId",
    );
    try {
      // 1. Get all contributions for the goal
      final contributions =
          await contributionDataSource.getContributionsForGoal(goalId);
      // 2. Calculate sum
      final double newTotalSaved = contributions.fold(
        0.0,
        (sum, c) => sum + c.amount,
      );
      log.fine("[ContributionRepo] Calculated new total saved: $newTotalSaved");
      // 3. Get the GoalModel
      final goalModel = await goalDataSource.getGoalById(goalId);
      if (goalModel == null) {
        log.warning(
          "[ContributionRepo] Goal not found (ID: $goalId) while trying to update cache.",
        );
        // This is problematic, but we might proceed without erroring out the contribution action
        return const Left(
          CacheFailure("Goal not found to update total saved cache."),
        );
      }
      // 4. Update the GoalModel's cache field
      final updatedGoalModel = GoalModel(
        id: goalModel.id,
        name: goalModel.name,
        targetAmount: goalModel.targetAmount,
        targetDate: goalModel.targetDate,
        iconName: goalModel.iconName,
        description: goalModel.description,
        statusIndex: goalModel.statusIndex,
        createdAt: goalModel.createdAt,
        achievedAt: goalModel.achievedAt,
        totalSavedCache: newTotalSaved, // Update the cache
      );
      // 5. Save the updated GoalModel
      await goalDataSource.saveGoal(updatedGoalModel);
      log.info(
        "[ContributionRepo] Successfully updated totalSaved cache for Goal ID $goalId to $newTotalSaved",
      );
      return const Right(null);
    } catch (e, s) {
      log.severe(
        "[ContributionRepo] Error updating total saved cache for goal $goalId$e$s",
      );
      return Left(
        CacheFailure(
          "Failed to update goal total saved cache: ${e.toString()}",
        ),
      );
    }
  }
  // --- End Helper ---

  @override
  Future<Either<Failure, GoalContribution>> addContribution(
    GoalContribution contribution,
  ) async {
    log.info(
      "[ContributionRepo] Adding contribution for Goal ID: ${contribution.goalId}",
    );
    try {
      final model = GoalContributionModel.fromEntity(contribution);
      await contributionDataSource.saveContribution(model);
      log.info(
        "[ContributionRepo] Contribution saved (ID: ${contribution.id}). Updating goal cache...",
      );
      // Update the cache AFTER successful save
      final cacheResult = await _updateGoalTotalSavedCache(contribution.goalId);
      if (cacheResult.isLeft()) {
        // Log warning but return success for the contribution itself
        log.warning(
          "[ContributionRepo] Failed to update goal cache after adding contribution ${contribution.id}.",
        );
      }
      return Right(contribution);
    } catch (e, s) {
      log.severe("[ContributionRepo] Error adding contribution$e$s");
      return Left(CacheFailure("Failed to add contribution: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> deleteContribution(
    String contributionId,
  ) async {
    log.info("[ContributionRepo] Deleting contribution ID: $contributionId");
    try {
      // Get goalId BEFORE deleting
      final model = await contributionDataSource.getContributionById(
        contributionId,
      );
      if (model == null) {
        log.warning(
          "[ContributionRepo] Contribution $contributionId not found for deletion.",
        );
        return const Left(CacheFailure("Contribution not found."));
      }
      final goalId = model.goalId;

      await contributionDataSource.deleteContribution(contributionId);
      log.info(
        "[ContributionRepo] Contribution deleted (ID: $contributionId). Updating goal cache...",
      );
      // Update cache AFTER successful delete
      final cacheResult = await _updateGoalTotalSavedCache(goalId);
      if (cacheResult.isLeft()) {
        log.warning(
          "[ContributionRepo] Failed to update goal cache after deleting contribution $contributionId.",
        );
      }
      return const Right(null);
    } catch (e, s) {
      log.severe(
        "[ContributionRepo] Error deleting contribution $contributionId$e$s",
      );
      return Left(
        CacheFailure("Failed to delete contribution: ${e.toString()}"),
      );
    }
  }

  @override
  Future<Either<Failure, List<GoalContribution>>> getContributionsForGoal(
    String goalId,
  ) async {
    log.fine("[ContributionRepo] Getting contributions for Goal ID: $goalId");
    try {
      final models = await contributionDataSource.getContributionsForGoal(
        goalId,
      );
      final entities = models.map((m) => m.toEntity()).toList();
      // Sort by date descending
      entities.sort((a, b) => b.date.compareTo(a.date));
      log.fine(
        "[ContributionRepo] Retrieved and sorted ${entities.length} contributions for goal $goalId.",
      );
      return Right(entities);
    } catch (e, s) {
      log.severe(
        "[ContributionRepo] Error getting contributions for goal $goalId$e$s",
      );
      return Left(
        CacheFailure("Failed to load contributions: ${e.toString()}"),
      );
    }
  }

  @override
  Future<Either<Failure, List<GoalContribution>>> getAllContributions() async {
    log.fine("[ContributionRepo] Getting all goal contributions");
    try {
      final models = await contributionDataSource.getAllContributions();
      final entities = models.map((m) => m.toEntity()).toList();
      // Sort by date descending for consistency
      entities.sort((a, b) => b.date.compareTo(a.date));
      log.fine(
        "[ContributionRepo] Retrieved ${entities.length} total contributions",
      );
      return Right(entities);
    } catch (e, s) {
      log.severe("[ContributionRepo] Error getting all contributions$e$s");
      return Left(
        CacheFailure("Failed to load contributions: ${e.toString()}"),
      );
    }
  }

  @override
  Future<Either<Failure, GoalContribution>> updateContribution(
    GoalContribution contribution,
  ) async {
    log.info("[ContributionRepo] Updating contribution ID: ${contribution.id}");
    try {
      final model = GoalContributionModel.fromEntity(contribution);
      await contributionDataSource.saveContribution(
        model,
      ); // Hive's put handles update
      log.info(
        "[ContributionRepo] Contribution updated (ID: ${contribution.id}). Updating goal cache...",
      );
      // Update cache AFTER successful update
      final cacheResult = await _updateGoalTotalSavedCache(contribution.goalId);
      if (cacheResult.isLeft()) {
        log.warning(
          "[ContributionRepo] Failed to update goal cache after updating contribution ${contribution.id}.",
        );
      }
      return Right(contribution);
    } catch (e, s) {
      log.severe(
        "[ContributionRepo] Error updating contribution ${contribution.id}$e$s",
      );
      return Left(
        CacheFailure("Failed to update contribution: ${e.toString()}"),
      );
    }
  }

  @override
  Future<Either<Failure, void>> auditGoalTotals() async {
    log.info("[ContributionRepo] Auditing cached totals for all goals");
    try {
      final goals = await goalDataSource.getGoals();
      for (final goal in goals) {
        final result = await _updateGoalTotalSavedCache(goal.id);
        if (result.isLeft()) {
          log.warning(
            "[ContributionRepo] Failed to sync total saved cache for goal ${goal.id}",
          );
        }
      }
      return const Right(null);
    } catch (e, s) {
      log.severe(
        "[ContributionRepo] Error auditing goal total saved caches$e$s",
      );
      return Left(
        CacheFailure(
          "Failed to audit goal total saved caches: ${e.toString()}",
        ),
      );
    }
  }
}
