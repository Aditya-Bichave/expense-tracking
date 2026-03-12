import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/domain/repositories/group_expenses_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class GroupExpensesEvent extends Equatable {
  const GroupExpensesEvent();

  @override
  List<Object?> get props => [];
}

class LoadGroupExpenses extends GroupExpensesEvent {
  final String groupId;

  const LoadGroupExpenses(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class AddGroupExpenseRequested extends GroupExpensesEvent {
  final GroupExpense expense;

  const AddGroupExpenseRequested(this.expense);

  @override
  List<Object?> get props => [expense];
}

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

  const GroupExpensesLoaded(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

class GroupExpensesError extends GroupExpensesState {
  final String message;

  const GroupExpensesError(this.message);

  @override
  List<Object?> get props => [message];
}

class GroupExpensesBloc extends Bloc<GroupExpensesEvent, GroupExpensesState> {
  final GroupExpensesRepository _repository;

  GroupExpensesBloc(this._repository) : super(const GroupExpensesInitial()) {
    on<LoadGroupExpenses>(_onLoadExpenses);
    on<AddGroupExpenseRequested>(_onAddExpense);
  }

  Future<void> _onLoadExpenses(
    LoadGroupExpenses event,
    Emitter<GroupExpensesState> emit,
  ) async {
    emit(const GroupExpensesLoading());

    final localResult = await _repository.getExpenses(event.groupId);
    List<GroupExpense> localExpenses = const <GroupExpense>[];
    var hasLocalData = false;

    localResult.fold(
      (failure) {
        emit(GroupExpensesError(failure.message));
      },
      (expenses) {
        hasLocalData = true;
        localExpenses = expenses;
        emit(GroupExpensesLoaded(expenses));
      },
    );

    if (!hasLocalData) {
      return;
    }

    final syncResult = await _repository.syncExpenses(event.groupId);
    if (syncResult.isLeft() && localExpenses.isEmpty) {
      emit(
        GroupExpensesError(
          syncResult.fold((failure) => failure.message, (_) => ''),
        ),
      );
      return;
    }

    final refreshedResult = await _repository.getExpenses(event.groupId);
    refreshedResult.fold(
      (failure) {
        if (localExpenses.isEmpty) {
          emit(GroupExpensesError(failure.message));
        }
      },
      (expenses) {
        if (expenses != localExpenses) {
          emit(GroupExpensesLoaded(expenses));
        }
      },
    );
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
