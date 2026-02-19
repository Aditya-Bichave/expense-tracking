import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';

abstract class GroupExpensesRepository {
  Future<Either<Failure, GroupExpense>> addExpense(GroupExpense expense);
  Future<Either<Failure, List<GroupExpense>>> getExpenses(String groupId);
  Future<Either<Failure, void>> syncExpenses(String groupId);
}
