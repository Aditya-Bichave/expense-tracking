// lib/features/goals/domain/usecases/audit_goal_totals.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';

/// Use case that audits all goals and recalculates their cached total saved
/// amounts. This can be run periodically or on startup to ensure the
/// `totalSavedCache` field of each goal remains in sync with its
/// contributions.
class AuditGoalTotalsUseCase implements UseCase<void, NoParams> {
  final GoalContributionRepository repository;

  AuditGoalTotalsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.auditGoalTotals();
  }
}
