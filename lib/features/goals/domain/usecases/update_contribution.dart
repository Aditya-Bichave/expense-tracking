// lib/features/goals/domain/usecases/update_contribution.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class UpdateContributionUseCase
    implements UseCase<GoalContribution, UpdateContributionParams> {
  final GoalContributionRepository repository;

  UpdateContributionUseCase(this.repository);

  @override
  Future<Either<Failure, GoalContribution>> call(
    UpdateContributionParams params,
  ) async {
    final contribution = params.contribution;
    log.info(
      "[UpdateContributionUseCase] Updating contribution ID: ${contribution.id}",
    );
    if (contribution.amount <= 0) {
      return const Left(
        ValidationFailure("Contribution amount must be positive."),
      );
    }
    return await repository.updateContribution(contribution);
  }
}

class UpdateContributionParams extends Equatable {
  final GoalContribution contribution;
  const UpdateContributionParams({required this.contribution});
  @override
  List<Object?> get props => [contribution];
}
