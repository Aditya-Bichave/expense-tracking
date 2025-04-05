// lib/features/goals/domain/usecases/delete_goal.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/main.dart';

class DeleteGoalUseCase implements UseCase<void, DeleteGoalParams> {
  final GoalRepository repository;

  DeleteGoalUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteGoalParams params) async {
    log.info("[DeleteGoalUseCase] Deleting goal ID: ${params.id}");
    // Repository implementation might handle cascade delete of contributions
    return await repository.deleteGoal(params.id);
  }
}

class DeleteGoalParams extends Equatable {
  final String id;
  const DeleteGoalParams({required this.id});
  @override
  List<Object?> get props => [id];
}
