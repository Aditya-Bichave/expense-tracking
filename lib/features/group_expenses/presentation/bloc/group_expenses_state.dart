import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';

abstract class GroupExpensesState extends Equatable {
  const GroupExpensesState();

  @override
  List<Object?> get props => [];
}

class GroupExpensesInitial extends GroupExpensesState {
  const GroupExpensesInitial();
}

class GroupExpensesLoading extends GroupExpensesState {
  const GroupExpensesLoading();
}

class GroupExpensesLoaded extends GroupExpensesState {
  final List<GroupExpense> expenses;
  final String? syncError;

  const GroupExpensesLoaded(this.expenses, {this.syncError});

  @override
  List<Object?> get props => [expenses, syncError];
}

class GroupExpensesError extends GroupExpensesState {
  final String message;

  const GroupExpensesError(this.message);

  @override
  List<Object?> get props => [message];
}
