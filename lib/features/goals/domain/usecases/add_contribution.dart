// lib/features/goals/domain/usecases/add_contribution.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/main.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/services/clock.dart';

class AddContributionUseCase
    implements UseCase<GoalContribution, AddContributionParams> {
  final GoalContributionRepository repository;
  final Uuid uuid;
  final Clock clock;

  AddContributionUseCase(this.repository, this.uuid, this.clock);

  @override
  Future<Either<Failure, GoalContribution>> call(
    AddContributionParams params,
  ) async {
    log.info(
      "[AddContributionUseCase] Adding contribution to Goal ID: ${params.goalId}",
    );

    if (params.amount <= 0) {
      return const Left(
        ValidationFailure("Contribution amount must be positive."),
      );
    }
    // Date validation usually handled by picker

    final newContribution = GoalContribution(
      id: uuid.v4(),
      goalId: params.goalId,
      amount: params.amount,
      date: params.date,
      note: params.note?.trim(),
      createdAt: clock.now(),
    );

    return await repository.addContribution(newContribution);
  }
}

class AddContributionParams extends Equatable {
  final String goalId;
  final double amount;
  final DateTime date;
  final String? note;

  const AddContributionParams({
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
  });

  @override
  List<Object?> get props => [goalId, amount, date, note];
}
