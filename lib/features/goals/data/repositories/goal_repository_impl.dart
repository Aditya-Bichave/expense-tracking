// lib/features/goals/data/repositories/goal_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart'; // Import contribution DS for delete cascading (optional but good practice)
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart'; // Import Status
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // For Contribution DS access during delete

class GoalRepositoryImpl implements GoalRepository {
  final GoalLocalDataSource localDataSource;
  // Optional: Inject contribution DS if you want repo to handle cascading deletes
  GoalContributionLocalDataSource get _contributionDataSource =>
      sl<GoalContributionLocalDataSource>();

  GoalRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Goal>> addGoal(Goal goal) async {
    log.info("[GoalRepo] Adding goal: ${goal.name}");
    try {
      // Cache is updated manually by ContributionRepo, so we use 0 here for add
      // Ensure status is active when adding
      final model = GoalModel.fromEntity(
          goal.copyWith(totalSaved: 0.0, status: GoalStatus.active));
      await localDataSource.saveGoal(model);
      log.info("[GoalRepo] Goal added successfully: ${goal.id}");
      return Right(model.toEntity()); // Return entity reflecting saved state
    } catch (e, s) {
      log.severe("[GoalRepo] Error adding goal$e$s");
      return Left(CacheFailure("Failed to add goal: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, Goal>> archiveGoal(String id) async {
    log.info("[GoalRepo] Archiving goal ID: $id");
    try {
      final model = await localDataSource.getGoalById(id);
      if (model == null) {
        log.warning("[GoalRepo] Goal not found for archiving: $id");
        return const Left(CacheFailure("Goal not found to archive."));
      }
      // Update status and save
      final updatedModel = GoalModel(
        id: model.id, name: model.name, targetAmount: model.targetAmount,
        targetDate: model.targetDate, iconName: model.iconName,
        description: model.description,
        statusIndex: GoalStatus.archived.index, // <-- Set status to archived
        totalSavedCache: model.totalSavedCache, // Keep existing cache
        createdAt: model.createdAt, achievedAt: model.achievedAt,
      );
      await localDataSource.saveGoal(updatedModel);
      log.info("[GoalRepo] Goal archived successfully: $id");
      return Right(updatedModel.toEntity()); // Return updated entity
    } catch (e, s) {
      log.severe("[GoalRepo] Error archiving goal $id$e$s");
      return Left(CacheFailure("Failed to archive goal: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGoal(String id) async {
    log.warning("[GoalRepo] Attempting PERMANENT delete for goal ID: $id.");

    // 1. Get the original goal and contributions to be able to restore them on failure.
    final originalGoalModel = await localDataSource.getGoalById(id);
    if (originalGoalModel == null) {
      return const Left(CacheFailure("Goal to delete not found."));
    }
    final originalContributions = await _contributionDataSource.getContributionsForGoal(id);

    try {
      // 2. Delete contributions first.
      log.info("[GoalRepo] Deleting ${originalContributions.length} contributions for goal $id.");
      for (final contribution in originalContributions) {
        await _contributionDataSource.deleteContribution(contribution.id);
      }

      // 3. Delete the goal itself.
      log.info("[GoalRepo] Deleting goal $id.");
      await localDataSource.deleteGoal(id);

      log.info("[GoalRepo] Goal and contributions permanently deleted: $id");
      return const Right(null);
    } catch (e, s) {
      log.severe("[GoalRepo] Error during transactional delete for goal $id: $e\n$s");

      // 4. Rollback on failure
      log.warning("[GoalRepo] Rolling back deletion for goal $id.");
      try {
        await localDataSource.saveGoal(originalGoalModel);
        for (final contribution in originalContributions) {
          await _contributionDataSource.saveContribution(contribution);
        }
        log.info("[GoalRepo] Rollback successful for goal $id.");
      } catch (rollbackError, rs) {
        log.severe("[GoalRepo] CRITICAL: Rollback FAILED for goal $id: $rollbackError\n$rs");
        return Left(CacheFailure("Failed to delete goal and could not automatically recover. Data might be inconsistent. Error: ${e.toString()}"));
      }

      return Left(CacheFailure("Failed to delete goal. Operation was rolled back. Error: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, Goal?>> getGoalById(String id) async {
    log.fine("[GoalRepo] Getting goal by ID: $id");
    try {
      final model = await localDataSource.getGoalById(id);
      if (model != null) {
        return Right(model.toEntity());
      } else {
        return const Right(null);
      }
    } catch (e, s) {
      log.severe("[GoalRepo] Error getting goal by ID $id$e$s");
      return Left(CacheFailure("Failed to get goal details: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, List<Goal>>> getGoals(
      {bool includeArchived = false}) async {
    log.fine("[GoalRepo] Getting goals. IncludeArchived: $includeArchived");
    try {
      final models = await localDataSource.getGoals();
      final entities = models.map((m) => m.toEntity()).where((g) {
        // Filter based on includeArchived flag
        return includeArchived || g.status != GoalStatus.archived;
      }).toList();

      // Sort by Percentage Complete (Descending), then by Creation Date Descending
      entities.sort((a, b) {
        int comparison = b.percentageComplete.compareTo(a.percentageComplete);
        if (comparison == 0) {
          comparison = b.createdAt.compareTo(a.createdAt);
        }
        return comparison;
      });

      log.info("[GoalRepo] Retrieved and sorted ${entities.length} goals.");
      return Right(entities);
    } catch (e, s) {
      log.severe("[GoalRepo] Error getting goals$e$s");
      return Left(CacheFailure("Failed to load goals: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, Goal>> updateGoal(Goal goal) async {
    log.info("[GoalRepo] Updating goal: ${goal.name}");
    try {
      // Retrieve the current cached totalSaved and achievedAt before saving
      final currentModel = await localDataSource.getGoalById(goal.id);
      if (currentModel == null) {
        return Left(
            CacheFailure("Goal with ID ${goal.id} not found for update."));
      }
      final currentTotalSaved = currentModel.totalSavedCache;
      final currentAchievedAt = currentModel.achievedAt;
      final currentStatusIndex = currentModel.statusIndex;

      // Determine the new status and achievedAt based on the update
      GoalStatus newStatus =
          goal.status; // Use status from incoming goal entity
      DateTime? newAchievedAt =
          goal.achievedAt; // Use incoming achievedAt initially

      // If status is being set to achieved and wasn't already, set achievedAt
      if (newStatus == GoalStatus.achieved &&
          currentStatusIndex != GoalStatus.achieved.index) {
        newAchievedAt = DateTime.now();
      } else if (newStatus != GoalStatus.achieved) {
        newAchievedAt =
            null; // Clear achievedAt if status is no longer achieved
      } else {
        newAchievedAt =
            currentAchievedAt; // Preserve existing achievedAt if status remains achieved
      }

      // Create the model to save, preserving the totalSaved cache but updating other fields
      final modelToSave = GoalModel(
        id: goal.id,
        name: goal.name,
        targetAmount: goal.targetAmount,
        targetDate: goal.targetDate,
        iconName: goal.iconName,
        description: goal.description,
        statusIndex: newStatus.index, // Use determined status
        totalSavedCache: currentTotalSaved, // Preserve the cache
        createdAt: goal.createdAt, // Preserve original createdAt
        achievedAt: newAchievedAt, // Use determined achievedAt
      );

      await localDataSource.saveGoal(modelToSave);
      log.info("[GoalRepo] Goal updated successfully: ${goal.id}");
      // Return the entity reflecting the saved state (including the PRESERVED totalSaved)
      return Right(modelToSave.toEntity());
    } catch (e, s) {
      log.severe("[GoalRepo] Error updating goal$e$s");
      return Left(CacheFailure("Failed to update goal: ${e.toString()}"));
    }
  }
}
