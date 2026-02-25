// lib/features/goals/domain/usecases/update_goal.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/main.dart';

class UpdateGoalUseCase implements UseCase<Goal, UpdateGoalParams> {
  final GoalRepository repository;

  UpdateGoalUseCase(this.repository);

  @override
  Future<Either<Failure, Goal>> call(UpdateGoalParams params) async {
    final goal = params.goal;
    log.info(
      "[UpdateGoalUseCase] Updating goal: ${goal.name} (ID: ${goal.id})",
    );

    // Validation (mirroring AddGoalUseCase)
    if (goal.name.trim().isEmpty) {
      return const Left(ValidationFailure("Goal name cannot be empty."));
    }
    if (goal.targetAmount <= 0) {
      return const Left(ValidationFailure("Target amount must be positive."));
    }
    // Past date validation can be skipped if allowed

    return await repository.updateGoal(goal);
  }
}

class UpdateGoalParams extends Equatable {
  final Goal goal; // Pass the full updated goal object
  const UpdateGoalParams({required this.goal});
  @override
  List<Object?> get props => [goal];
}
