// lib/features/goals/domain/usecases/get_contributions_for_goal.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/main.dart';

class GetContributionsForGoalUseCase
    implements UseCase<List<GoalContribution>, GetContributionsParams> {
  final GoalContributionRepository repository;

  GetContributionsForGoalUseCase(this.repository);

  @override
  Future<Either<Failure, List<GoalContribution>>> call(
      GetContributionsParams params) async {
    log.info(
        "[GetContributionsUseCase] Fetching contributions for Goal ID: ${params.goalId}");
    return await repository.getContributionsForGoal(params.goalId);
  }
}

class GetContributionsParams extends Equatable {
  final String goalId;
  const GetContributionsParams({required this.goalId});
  @override
  List<Object?> get props => [goalId];
}
