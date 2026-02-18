import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/groups/domain/repositories/group_expenses_repository.dart';

class SyncGroupExpensesParams {
  final String groupId;
  SyncGroupExpensesParams(this.groupId);
}

class SyncGroupExpensesUseCase
    implements UseCase<void, SyncGroupExpensesParams> {
  final GroupExpensesRepository repository;

  SyncGroupExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SyncGroupExpensesParams params) {
    return repository.syncExpenses(params.groupId);
  }
}
