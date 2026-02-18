import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_expense_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/group_expenses_repository.dart';

class AddGroupExpenseUseCase
    implements UseCase<GroupExpenseEntity, GroupExpenseEntity> {
  final GroupExpensesRepository repository;

  AddGroupExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, GroupExpenseEntity>> call(GroupExpenseEntity params) {
    return repository.addExpense(params);
  }
}
