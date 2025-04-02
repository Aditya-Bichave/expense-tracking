import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart'; // Make sure Failure is imported
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/get_expenses.dart';

// Link the state and event files to this bloc file
part 'expense_list_event.dart';
part 'expense_list_state.dart';

class ExpenseListBloc extends Bloc<ExpenseListEvent, ExpenseListState> {
  final GetExpensesUseCase _getExpensesUseCase; // Renamed for convention
  final DeleteExpenseUseCase _deleteExpenseUseCase; // Renamed for convention

  // Keep track of current filters. This could also be solely managed within the state.
  // Storing them here allows easy access when reloading without explicitly passing them again.
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  String? _currentCategory;

  ExpenseListBloc({
    required GetExpensesUseCase getExpensesUseCase,
    required DeleteExpenseUseCase deleteExpenseUseCase,
  })  : _getExpensesUseCase = getExpensesUseCase, // Assign renamed variable
        _deleteExpenseUseCase = deleteExpenseUseCase, // Assign renamed variable
        super(ExpenseListInitial()) {
    // Set initial state
    // Register event handlers
    on<LoadExpenses>(_onLoadExpenses);
    on<FilterExpenses>(_onFilterExpenses);
    on<DeleteExpenseRequested>(_onDeleteExpenseRequested);
  }

  // Handler for loading expenses (initial load or refresh)
  Future<void> _onLoadExpenses(
      LoadExpenses event, Emitter<ExpenseListState> emit) async {
    // Emit loading state *only if* not already in a loaded state
    // This prevents flicker during refresh if we want to keep showing old data
    if (state is! ExpenseListLoaded) {
      emit(ExpenseListLoading());
    }

    // Use the stored filters for reloading/refreshing
    final params = GetExpensesParams(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      category: _currentCategory,
    );

    final result = await _getExpensesUseCase(params);

    result.fold(
      // On Failure
      (failure) => emit(ExpenseListError(_mapFailureToMessage(failure))),
      // On Success
      (expenses) => emit(ExpenseListLoaded(
        expenses: expenses,
        filterStartDate: _currentStartDate, // Pass current filters to the state
        filterEndDate: _currentEndDate,
        filterCategory: _currentCategory,
      )),
    );
  }

  // Handler for applying new filters
  Future<void> _onFilterExpenses(
      FilterExpenses event, Emitter<ExpenseListState> emit) async {
    emit(ExpenseListLoading()); // Show loading indicator while filtering

    // Update the stored filters
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _currentCategory = event.category;

    // Create params with the new filters from the event
    final params = GetExpensesParams(
      startDate: event.startDate,
      endDate: event.endDate,
      category: event.category,
    );

    final result = await _getExpensesUseCase(params);

    result.fold(
      // On Failure
      (failure) => emit(ExpenseListError(_mapFailureToMessage(failure))),
      // On Success
      (expenses) => emit(ExpenseListLoaded(
        expenses: expenses,
        filterStartDate: _currentStartDate, // Pass the newly applied filters
        filterEndDate: _currentEndDate,
        filterCategory: _currentCategory,
      )),
    );
  }

  // Handler for requesting deletion of an expense
  Future<void> _onDeleteExpenseRequested(
      DeleteExpenseRequested event, Emitter<ExpenseListState> emit) async {
    final currentState =
        state; // Capture the current state before async operation

    if (currentState is ExpenseListLoaded) {
      // --- Optimistic UI Update (Optional but recommended for better UX) ---
      // Immediately remove the item from the list shown in the UI
      final optimisticList = currentState.expenses
          .where((exp) => exp.id != event.expenseId)
          .toList();

      // Emit the loaded state with the item already removed
      emit(ExpenseListLoaded(
        expenses: optimisticList,
        filterStartDate: currentState.filterStartDate,
        filterEndDate: currentState.filterEndDate,
        filterCategory: currentState.filterCategory,
      ));
      // --------------------------------------------------------------------

      // Call the delete use case
      final result =
          await _deleteExpenseUseCase(DeleteExpenseParams(event.expenseId));

      result.fold(
        // On Failure (Deletion failed)
        (failure) {
          // Revert the optimistic update by emitting the original state (or reloading)
          // And show an error message
          emit(currentState); // Revert UI back to before optimistic delete
          // Or emit error state without reverting list:
          // emit(currentState.copyWith(errorMessage: _mapFailureToMessage(failure))); // Need copyWith in state
          emit(ExpenseListError(
              "Failed to delete: ${_mapFailureToMessage(failure)}")); // Show error separately
          // Optionally reload the list to ensure data consistency after failure
          // add(LoadExpenses());
        },
        // On Success (Deletion successful)
        (_) {
          // If optimistic UI was used, we are already in the correct state.
          // If optimistic UI was *not* used, we need to reload the list here:
          // add(LoadExpenses());
        },
      );
    }
    // If the state is not ExpenseListLoaded when delete is requested,
    // we might log an error or ignore the event, as there's no list to modify.
  }

  // Helper to convert Failures to user-readable messages
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'Database Error: ${failure.message}';
      // Add other specific failure types if needed
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }
}

// Ensure Params classes are accessible here (defined in use case files or shared location)
// Example re-definitions if not imported correctly:
/*
class GetExpensesParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  const GetExpensesParams({this.startDate, this.endDate, this.category});
  @override List<Object?> get props => [startDate, endDate, category];
}

class DeleteExpenseParams extends Equatable {
  final String id;
  const DeleteExpenseParams(this.id);
   @override List<Object?> get props => [id];
}
*/