// lib/features/goals/domain/usecases/check_goal_achievement.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/main.dart';

class CheckGoalAchievementUseCase implements UseCase<bool, CheckGoalParams> {
  final GoalRepository repository;

  CheckGoalAchievementUseCase(this.repository);

  /// Checks if a goal is achieved and updates its status if necessary.
  /// Returns `true` if the goal status was *changed* to achieved, `false` otherwise.
  @override
  Future<Either<Failure, bool>> call(CheckGoalParams params) async {
    log.info(
      "[CheckGoalAchievementUseCase] Checking achievement for Goal ID: ${params.goalId}",
    );
    try {
      // 1. Get the latest goal state
      final goalResult = await repository.getGoalById(params.goalId);
      return await goalResult.fold(
        (failure) {
          log.warning(
            "[CheckGoalAchievementUseCase] Failed to get goal ${params.goalId}: ${failure.message}",
          );
          return Left<Failure, bool>(failure); // Propagate failure
        },
        (goal) async {
          if (goal == null) {
            log.warning(
              "[CheckGoalAchievementUseCase] Goal ${params.goalId} not found.",
            );
            return const Left<Failure, bool>(CacheFailure("Goal not found."));
          }

          // 2. Check conditions
          final bool alreadyAchieved = goal.status == GoalStatus.achieved;
          final bool nowAchieved = goal.totalSaved >= goal.targetAmount;

          if (nowAchieved && !alreadyAchieved) {
            log.info(
              "[CheckGoalAchievementUseCase] Goal ${params.goalId} newly achieved! Updating status.",
            );
            // 3. Update status via repository (which also sets achievedAt)
            final updateResult = await repository.updateGoal(
              goal.copyWith(status: GoalStatus.achieved),
            );
            return updateResult.fold(
              (failure) {
                log.warning(
                  "[CheckGoalAchievementUseCase] Failed to update goal status for ${params.goalId}: ${failure.message}",
                );
                return Left<Failure, bool>(failure);
              },
              (_) {
                log.info(
                  "[CheckGoalAchievementUseCase] Goal ${params.goalId} status updated to achieved.",
                );
                return const Right<Failure, bool>(true); // Status CHANGED
              },
            );
          } else {
            log.fine(
              "[CheckGoalAchievementUseCase] Goal ${params.goalId} status unchanged (AlreadyAchieved: $alreadyAchieved, NowAchieved: $nowAchieved).",
            );
            return const Right<Failure, bool>(false); // Status did not change
          }
        },
      );
    } catch (e, s) {
      log.severe(
        "[CheckGoalAchievementUseCase] Unexpected error for goal ${params.goalId}$e$s",
      );
      return Left<Failure, bool>(
        UnexpectedFailure("Error checking goal achievement: ${e.toString()}"),
      );
    }
  }
}

class CheckGoalParams extends Equatable {
  final String goalId;
  const CheckGoalParams({required this.goalId});
  @override
  List<Object?> get props => [goalId];
}
