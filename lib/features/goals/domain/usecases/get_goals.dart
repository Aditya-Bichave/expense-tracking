// lib/features/goals/domain/usecases/get_goals.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class GetGoalsUseCase implements UseCase<List<Goal>, NoParams> {
  final GoalRepository repository;

  GetGoalsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Goal>>> call(NoParams params) async {
    log.info("[GetGoalsUseCase] Fetching active goals.");
    // For V1 list view, only fetch active goals
    return await repository.getGoals(includeArchived: false);
  }
}
