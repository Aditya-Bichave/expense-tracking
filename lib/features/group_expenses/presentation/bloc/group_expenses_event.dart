import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';

abstract class GroupExpensesEvent extends Equatable {
  const GroupExpensesEvent();

  @override
  List<Object> get props => [];
}

class LoadGroupExpenses extends GroupExpensesEvent {
  final String groupId;

  const LoadGroupExpenses(this.groupId);

  @override
  List<Object> get props => [groupId];
}

class AddGroupExpenseRequested extends GroupExpensesEvent {
  final GroupExpense expense;

  const AddGroupExpenseRequested(this.expense);

  @override
  List<Object> get props => [expense];
}

class UpdateGroupExpenseRequested extends GroupExpensesEvent {
  final GroupExpense expense;

  const UpdateGroupExpenseRequested(this.expense);

  @override
  List<Object> get props => [expense];
}

class DeleteGroupExpenseRequested extends GroupExpensesEvent {
  final String expenseId;

  const DeleteGroupExpenseRequested(this.expenseId);

  @override
  List<Object> get props => [expenseId];
}
