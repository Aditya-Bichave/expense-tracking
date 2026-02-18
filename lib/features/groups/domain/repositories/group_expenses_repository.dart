import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_expense_entity.dart';

abstract class GroupExpensesRepository {
  Future<Either<Failure, List<GroupExpenseEntity>>> getExpenses(String groupId);
  Future<Either<Failure, GroupExpenseEntity>> addExpense(
    GroupExpenseEntity expense,
  );
  Future<Either<Failure, void>> syncExpenses(String groupId);
}
