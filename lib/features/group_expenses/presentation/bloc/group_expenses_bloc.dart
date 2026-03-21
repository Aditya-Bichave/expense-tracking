import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/domain/repositories/group_expenses_repository.dart';

import 'group_expenses_event.dart';
import 'group_expenses_state.dart';

class GroupExpensesBloc extends Bloc<GroupExpensesEvent, GroupExpensesState> {
  final GroupExpensesRepository _repository;

  // Pending mutations queue to re-evaluate when we get a loaded state.
  final List<GroupExpensesEvent> _pendingMutations = [];

  GroupExpensesBloc(this._repository) : super(const GroupExpensesInitial()) {
    on<LoadGroupExpenses>(_onLoadExpenses);
    on<AddGroupExpenseRequested>(_onAddExpense);
    on<UpdateGroupExpenseRequested>(_onUpdateExpense);
    on<DeleteGroupExpenseRequested>(_onDeleteExpense);
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

    _processPendingMutations();

    if (!hasLocalData) {
      return;
    }

    final remoteResult = await _repository.syncExpenses(event.groupId);
    await remoteResult.fold(
      (failure) async {
        emit(GroupExpensesLoaded(localExpenses, syncError: failure.message));
      },
      (_) async {
        final syncedResult = await _repository.getExpenses(event.groupId);
        syncedResult.fold(
          (failure) => emit(GroupExpensesError(failure.message)),
          (syncedExpenses) {
            emit(GroupExpensesLoaded(syncedExpenses));
            _processPendingMutations();
          },
        );
      },
    );
  }

  void _processPendingMutations() {
    if (state is GroupExpensesLoaded && _pendingMutations.isNotEmpty) {
      final eventsToProcess = List<GroupExpensesEvent>.from(_pendingMutations);
      _pendingMutations.clear();
      for (final event in eventsToProcess) {
        add(event);
      }
    }
  }

  Future<void> _onAddExpense(
    AddGroupExpenseRequested event,
    Emitter<GroupExpensesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GroupExpensesLoaded) {
      _pendingMutations.add(event);
      return;
    }

    emit(const GroupExpensesLoading());

    final result = await _repository.addExpense(event.expense);

    result.fold(
      (failure) {
        emit(
          GroupExpensesOperationFailed(failure.message, currentState.expenses),
        );
        emit(GroupExpensesLoaded(currentState.expenses));
      },
      (expense) {
        emit(GroupExpenseOperationSucceeded(expense));
        emit(GroupExpensesLoaded([expense, ...currentState.expenses]));
      },
    );
  }

  Future<void> _onUpdateExpense(
    UpdateGroupExpenseRequested event,
    Emitter<GroupExpensesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GroupExpensesLoaded) {
      _pendingMutations.add(event);
      return;
    }

    emit(const GroupExpensesLoading());

    final result = await _repository.updateExpense(event.expense);

    result.fold(
      (failure) {
        emit(
          GroupExpensesOperationFailed(failure.message, currentState.expenses),
        );
        emit(GroupExpensesLoaded(currentState.expenses));
      },
      (updatedExpense) {
        final newExpenses = currentState.expenses.map((e) {
          return e.id == updatedExpense.id ? updatedExpense : e;
        }).toList();
        emit(GroupExpenseOperationSucceeded(updatedExpense));
        emit(GroupExpensesLoaded(newExpenses));
      },
    );
  }

  Future<void> _onDeleteExpense(
    DeleteGroupExpenseRequested event,
    Emitter<GroupExpensesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GroupExpensesLoaded) {
      _pendingMutations.add(event);
      return;
    }

    emit(const GroupExpensesLoading());

    final result = await _repository.deleteExpense(event.expenseId);

    result.fold(
      (failure) {
        emit(
          GroupExpensesOperationFailed(failure.message, currentState.expenses),
        );
        emit(GroupExpensesLoaded(currentState.expenses));
      },
      (_) {
        final newExpenses = currentState.expenses
            .where((e) => e.id != event.expenseId)
            .toList();
        emit(const GroupExpenseOperationSucceeded(null));
        emit(GroupExpensesLoaded(newExpenses));
      },
    );
  }
}
