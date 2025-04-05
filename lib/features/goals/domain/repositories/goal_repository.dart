// lib/features/goals/domain/repositories/goal_repository.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';

abstract class GoalRepository {
  Future<Either<Failure, List<Goal>>> getGoals({bool includeArchived = false});
  Future<Either<Failure, Goal?>> getGoalById(String id);
  Future<Either<Failure, Goal>> addGoal(Goal goal);
  Future<Either<Failure, Goal>> updateGoal(Goal goal);
  Future<Either<Failure, void>> deleteGoal(
      String id); // Keep delete for now if needed
  Future<Either<Failure, Goal>> archiveGoal(String id); // ADDED
}
