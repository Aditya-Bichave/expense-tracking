// lib/features/goals/domain/repositories/goal_contribution_repository.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';

abstract class GoalContributionRepository {
  Future<Either<Failure, List<GoalContribution>>> getContributionsForGoal(
      String goalId);
  Future<Either<Failure, GoalContribution>> addContribution(
      GoalContribution contribution);
  Future<Either<Failure, GoalContribution>> updateContribution(
      GoalContribution contribution);
  Future<Either<Failure, void>> deleteContribution(String contributionId);
}
