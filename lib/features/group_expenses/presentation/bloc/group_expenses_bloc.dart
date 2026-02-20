import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/domain/repositories/group_expenses_repository.dart';

// Events
abstract class GroupExpensesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadGroupExpenses extends GroupExpensesEvent {
  final String groupId;
  LoadGroupExpenses(this.groupId);
}

class AddGroupExpenseRequested extends GroupExpensesEvent {
  final GroupExpense expense;
  AddGroupExpenseRequested(this.expense);
}

// States
abstract class GroupExpensesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GroupExpensesInitial extends GroupExpensesState {}

class GroupExpensesLoading extends GroupExpensesState {}

class GroupExpensesLoaded extends GroupExpensesState {
  final List<GroupExpense> expenses;
  GroupExpensesLoaded(this.expenses);
  @override
  List<Object?> get props => [expenses];
}

class GroupExpensesError extends GroupExpensesState {
  final String message;
  GroupExpensesError(this.message);
  @override
  List<Object?> get props => [message];
}

class GroupExpensesBloc extends Bloc<GroupExpensesEvent, GroupExpensesState> {
  final GroupExpensesRepository _repository;

  GroupExpensesBloc(this._repository) : super(GroupExpensesInitial()) {
    on<LoadGroupExpenses>(_onLoadExpenses);
    on<AddGroupExpenseRequested>(_onAddExpense);
  }

  Future<void> _onLoadExpenses(
    LoadGroupExpenses event,
    Emitter<GroupExpensesState> emit,
  ) async {
    emit(GroupExpensesLoading());
    final result = await _repository.getExpenses(event.groupId);
    result.fold(
      (failure) => emit(GroupExpensesError(failure.message)),
      (expenses) => emit(GroupExpensesLoaded(expenses)),
    );

    // Sync
    _repository.syncExpenses(event.groupId).then((_) {
      add(LoadGroupExpenses(event.groupId));
    });
  }

  Future<void> _onAddExpense(
    AddGroupExpenseRequested event,
    Emitter<GroupExpensesState> emit,
  ) async {
    final result = await _repository.addExpense(event.expense);
    result.fold(
      (failure) => emit(GroupExpensesError(failure.message)),
      (expense) => add(LoadGroupExpenses(expense.groupId)),
    );
  }
}
