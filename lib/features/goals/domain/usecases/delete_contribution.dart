// lib/features/goals/domain/usecases/delete_contribution.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/main.dart';

class DeleteContributionUseCase
    implements UseCase<void, DeleteContributionParams> {
  final GoalContributionRepository repository;

  DeleteContributionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteContributionParams params) async {
    log.info(
      "[DeleteContributionUseCase] Deleting contribution ID: ${params.id}",
    );
    return await repository.deleteContribution(params.id);
  }
}

class DeleteContributionParams extends Equatable {
  final String id;
  const DeleteContributionParams({required this.id});
  @override
  List<Object?> get props => [id];
}
