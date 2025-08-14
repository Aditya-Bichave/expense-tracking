import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';

class AcknowledgeGoalAchievedUseCase implements UseCase<void, String> {
  final GoalRepository repository;

  AcknowledgeGoalAchievedUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) {
    return repository.acknowledgeGoalAchieved(params);
  }
}
