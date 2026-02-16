// lib/features/goals/domain/usecases/add_goal.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/main.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/services/clock.dart';

class AddGoalUseCase implements UseCase<Goal, AddGoalParams> {
  final GoalRepository repository;
  final Uuid uuid;
  final Clock clock;

  AddGoalUseCase(this.repository, this.uuid, this.clock);

  @override
  Future<Either<Failure, Goal>> call(AddGoalParams params) async {
    log.info("[AddGoalUseCase] Adding goal: ${params.name}");

    // Validation
    if (params.name.trim().isEmpty) {
      return const Left(ValidationFailure("Goal name cannot be empty."));
    }
    if (params.targetAmount <= 0) {
      return const Left(ValidationFailure("Target amount must be positive."));
    }
    if (params.targetDate != null &&
        params.targetDate!.isBefore(
          clock.now().subtract(const Duration(days: 1)),
        )) {
      // Allow today, but not past days
      // return const Left(ValidationFailure("Target date cannot be in the past."));
      // Let's allow past dates for flexibility (e.g., logging a past goal)
    }
    if (params.iconName == null || params.iconName!.isEmpty) {
      // Use a default if not provided, so no validation failure needed
      // Could log a warning if desired.
    }

    final newGoal = Goal(
      id: uuid.v4(),
      name: params.name.trim(),
      targetAmount: params.targetAmount,
      targetDate: params.targetDate,
      iconName: params.iconName ?? 'savings', // Default icon
      description: params.description?.trim(),
      status: GoalStatus.active,
      totalSaved: 0.0, // Initial saved amount is 0
      createdAt: clock.now(),
      achievedAt: null,
    );

    return await repository.addGoal(newGoal);
  }
}

class AddGoalParams extends Equatable {
  final String name;
  final double targetAmount;
  final DateTime? targetDate;
  final String? iconName;
  final String? description;

  const AddGoalParams({
    required this.name,
    required this.targetAmount,
    this.targetDate,
    this.iconName,
    this.description,
  });

  @override
  List<Object?> get props => [
    name,
    targetAmount,
    targetDate,
    iconName,
    description,
  ];
}
