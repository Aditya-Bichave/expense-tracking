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

class GoalRepositoryImpl implements GoalRepository {
  final GoalLocalDataSource localDataSource;
  final GoalContributionLocalDataSource contributionDataSource;

  GoalRepositoryImpl({
    required this.localDataSource,
    required this.contributionDataSource,
  });

  @override
  Future<Either<Failure, Goal>> addGoal(Goal goal) async {
    log.info("[GoalRepo] Adding goal: ${goal.name}");
    try {
      // Cache is updated manually by ContributionRepo, so we use 0 here for add
      // Ensure status is active when adding
      final model = GoalModel.fromEntity(
        goal.copyWith(totalSaved: 0.0, status: GoalStatus.active),
      );
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
        id: model.id,
        name: model.name,
        targetAmount: model.targetAmount,
        targetDate: model.targetDate,
        iconName: model.iconName,
        description: model.description,
        statusIndex: GoalStatus.archived.index, // <-- Set status to archived
        totalSavedCache: model.totalSavedCache, // Keep existing cache
        createdAt: model.createdAt,
        achievedAt: model.achievedAt,
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
    // **Warning:** Permanent delete. Archiving is preferred.
    log.warning(
      "[GoalRepo] Attempting PERMANENT delete for goal ID: $id. Archive is preferred.",
    );
    try {
      // --- Optional: Cascade delete contributions ---
      log.info(
        "[GoalRepo] Deleting associated contributions for Goal ID: $id...",
      );
      final contributions = await contributionDataSource
          .getContributionsForGoal(id);
      final contributionIds = contributions.map((c) => c.id).toList();
      await contributionDataSource.deleteContributions(contributionIds);
      log.info(
        "[GoalRepo] Deleted ${contributions.length} associated contributions.",
      );
      // --- End Optional Cascade ---

      await localDataSource.deleteGoal(id);
      log.info("[GoalRepo] Goal permanently deleted: $id");
      return const Right(null);
    } catch (e, s) {
      log.severe("[GoalRepo] Error deleting goal $id$e$s");
      return Left(CacheFailure("Failed to delete goal: ${e.toString()}"));
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
  Future<Either<Failure, List<Goal>>> getGoals({
    bool includeArchived = false,
  }) async {
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
          CacheFailure("Goal with ID ${goal.id} not found for update."),
        );
      }
      final currentTotalSaved = currentModel.totalSavedCache;
      final currentAchievedAt = currentModel.achievedAt;

      // Determine the new status and achievedAt based on current progress
      GoalStatus newStatus;
      DateTime? newAchievedAt;

      final isAchieved = currentTotalSaved >= goal.targetAmount;
      if (isAchieved) {
        newStatus = GoalStatus.achieved;
        newAchievedAt = currentAchievedAt ?? DateTime.now();
      } else {
        // If goal isn't achieved, keep archived status if explicitly set
        newStatus = goal.status == GoalStatus.archived
            ? GoalStatus.archived
            : GoalStatus.active;
        newAchievedAt = null; // Clear achieved timestamp if no longer achieved
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
