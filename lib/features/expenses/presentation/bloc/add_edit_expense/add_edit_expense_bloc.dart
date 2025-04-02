import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'
    hide Category; // Hide foundation's Category
import 'package:uuid/uuid.dart'; // To generate IDs for new expenses
import 'package:expense_tracker/core/error/failure.dart';
// import 'package:expense_tracker/core/utils/enums.dart'; // FormStatus is now defined in state file
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/category.dart'; // Import *our* Category
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl helper
import 'package:expense_tracker/core/events/data_change_event.dart'; // Import event

// Link the corresponding event and state files
part 'add_edit_expense_event.dart';
part 'add_edit_expense_state.dart';

class AddEditExpenseBloc
    extends Bloc<AddEditExpenseEvent, AddEditExpenseState> {
  final AddExpenseUseCase _addExpenseUseCase;
  final UpdateExpenseUseCase _updateExpenseUseCase;
  final Uuid _uuid; // For generating unique IDs

  AddEditExpenseBloc({
    required AddExpenseUseCase addExpenseUseCase,
    required UpdateExpenseUseCase updateExpenseUseCase,
    Expense? initialExpense, // Optionally pass initial expense for editing mode
  })  : _addExpenseUseCase = addExpenseUseCase,
        _updateExpenseUseCase = updateExpenseUseCase,
        _uuid = const Uuid(), // Initialize Uuid generator
        // Set the initial state, including the initial expense if provided
        super(AddEditExpenseState(initialExpense: initialExpense)) {
    // Register the event handler for when the save action is requested
    on<SaveExpenseRequested>(_onSaveExpenseRequested);
  }

  // Handles the SaveExpenseRequested event
  Future<void> _onSaveExpenseRequested(
      SaveExpenseRequested event, Emitter<AddEditExpenseState> emit) async {
    // Emit submitting state and clear any previous errors
    emit(state.copyWith(status: FormStatus.submitting, clearError: true));

    // Construct the Expense entity from the event data
    final bool isEditing = event.existingExpenseId != null;
    final expenseToSave = Expense(
      // Use existing ID if editing, otherwise generate a new one
      id: event.existingExpenseId ?? _uuid.v4(),
      title: event.title,
      amount: event.amount,
      date: event.date,
      category: event.category, // Use our Category entity
      accountId: event.accountId,
    );

    // Determine whether to call the update or add use case
    final result = isEditing
        ? await _updateExpenseUseCase(UpdateExpenseParams(expenseToSave))
        : await _addExpenseUseCase(AddExpenseParams(expenseToSave));

    // Process the result from the use case
    result.fold(
        // On Failure
        (failure) {
      // Emit error state with a mapped message
      emit(state.copyWith(
          status: FormStatus.error,
          errorMessage: _mapFailureToMessage(failure)));
    },
        // On Success
        (_) {
      emit(state.copyWith(status: FormStatus.success)); // Emit success state
      // *** Publish Event on Success ***
      publishDataChangedEvent(
          type: DataChangeType.expense,
          reason:
              isEditing ? DataChangeReason.updated : DataChangeReason.added);
      // *********************************
    });
  }

  // Helper function to convert Failure objects into user-friendly error messages
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message; // Use specific validation message
      case CacheFailure:
        return 'Database Error: ${failure.message}';
      // Add other failure types (e.g., ServerFailure) if needed
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }
}
