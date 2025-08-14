// lib/features/goals/domain/repositories/goal_contribution_repository.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';

abstract class GoalContributionRepository {
  Future<Either<Failure, List<GoalContribution>>> getContributionsForGoal(
    String goalId,
  );
  Future<Either<Failure, List<GoalContribution>>> getAllContributions();
  Future<Either<Failure, GoalContribution>> addContribution(
    GoalContribution contribution,
  );
  Future<Either<Failure, GoalContribution>> updateContribution(
    GoalContribution contribution,
  );
  Future<Either<Failure, void>> deleteContribution(String contributionId);

  /// Audits all goals and recalculates the cached total saved amount.
  ///
  /// This can be used by a periodic background task to ensure that the
  /// `totalSavedCache` field on each goal remains accurate even if an earlier
  /// operation crashed before the cache was updated.
  Future<Either<Failure, void>> auditGoalTotals();
}
