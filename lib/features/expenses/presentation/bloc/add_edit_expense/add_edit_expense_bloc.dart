import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/utils/enums.dart'; // Shared FormStatus
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl helper & publish
import 'package:expense_tracker/core/events/data_change_event.dart'; // Import event

part 'add_edit_expense_event.dart';
part 'add_edit_expense_state.dart';

class AddEditExpenseBloc
    extends Bloc<AddEditExpenseEvent, AddEditExpenseState> {
  final AddExpenseUseCase _addExpenseUseCase;
  final UpdateExpenseUseCase _updateExpenseUseCase;
  final Uuid _uuid;

  AddEditExpenseBloc({
    required AddExpenseUseCase addExpenseUseCase,
    required UpdateExpenseUseCase updateExpenseUseCase,
    Expense? initialExpense,
  })  : _addExpenseUseCase = addExpenseUseCase,
        _updateExpenseUseCase = updateExpenseUseCase,
        _uuid = const Uuid(),
        super(AddEditExpenseState(initialExpense: initialExpense)) {
    on<SaveExpenseRequested>(_onSaveExpenseRequested);
    log.info(
        "[AddEditExpenseBloc] Initialized. Editing: ${initialExpense != null}");
  }

  Future<void> _onSaveExpenseRequested(
      SaveExpenseRequested event, Emitter<AddEditExpenseState> emit) async {
    log.info("[AddEditExpenseBloc] Received SaveExpenseRequested.");
    emit(state.copyWith(status: FormStatus.submitting, clearError: true));

    final bool isEditing = event.existingExpenseId != null;
    final expenseToSave = Expense(
      id: event.existingExpenseId ?? _uuid.v4(),
      title: event.title,
      amount: event.amount,
      date: event.date,
      category: event.category,
      accountId: event.accountId,
    );

    log.info(
        "[AddEditExpenseBloc] Calling ${isEditing ? 'Update' : 'Add'} use case for '${expenseToSave.title}'.");
    final result = isEditing
        ? await _updateExpenseUseCase(UpdateExpenseParams(expenseToSave))
        : await _addExpenseUseCase(AddExpenseParams(expenseToSave));

    result.fold(
      (failure) {
        log.warning("[AddEditExpenseBloc] Save failed: ${failure.message}");
        emit(state.copyWith(
            status: FormStatus.error,
            errorMessage: _mapFailureToMessage(failure)));
      },
      (savedExpense) {
        log.info(
            "[AddEditExpenseBloc] Save successful for '${savedExpense.title}'. Emitting Success status and publishing event.");
        emit(state.copyWith(status: FormStatus.success));
        publishDataChangedEvent(
          type: DataChangeType.expense,
          reason: isEditing ? DataChangeReason.updated : DataChangeReason.added,
        );
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    log.warning(
        "[AddEditExpenseBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message;
      case CacheFailure:
        return 'Database Error: Could not save expense. ${failure.message}';
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }
}
