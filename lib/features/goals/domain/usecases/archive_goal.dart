// lib/features/goals/domain/usecases/archive_goal.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/main.dart';

class ArchiveGoalUseCase implements UseCase<void, ArchiveGoalParams> {
  final GoalRepository repository;

  ArchiveGoalUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ArchiveGoalParams params) async {
    log.info("[ArchiveGoalUseCase] Archiving goal ID: ${params.id}");
    // Repository implementation will handle fetching the goal and updating its status
    final result = await repository.archiveGoal(params.id);
    // Return Right(null) on success, Left(failure) on error
    return result.fold(
      (l) => Left(l),
      (_) => const Right(null), // Map successful Goal return to void
    );
  }
}

class ArchiveGoalParams extends Equatable {
  final String id;
  const ArchiveGoalParams({required this.id});
  @override
  List<Object?> get props => [id];
}
