import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_expense_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/group_expenses_repository.dart';

class GetGroupExpensesParams {
  final String groupId;
  GetGroupExpensesParams(this.groupId);
}

class GetGroupExpensesUseCase implements UseCase<List<GroupExpenseEntity>, GetGroupExpensesParams> {
  final GroupExpensesRepository repository;

  GetGroupExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, List<GroupExpenseEntity>>> call(GetGroupExpensesParams params) {
    return repository.getExpenses(params.groupId);
  }
}
