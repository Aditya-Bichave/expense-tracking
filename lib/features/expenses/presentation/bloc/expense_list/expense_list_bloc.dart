import 'dart:async'; // Import async
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:expense_tracker/core/error/failure.dart'; // Make sure Failure is imported
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/get_expenses.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl helper
import 'package:expense_tracker/core/events/data_change_event.dart'; // Import event

part 'expense_list_event.dart';
part 'expense_list_state.dart';

class ExpenseListBloc extends Bloc<ExpenseListEvent, ExpenseListState> {
  final GetExpensesUseCase _getExpensesUseCase;
  final DeleteExpenseUseCase _deleteExpenseUseCase;
  late final StreamSubscription<DataChangedEvent>
      _dataChangeSubscription; // Subscription

  // Store current filters to re-apply on refresh
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  String? _currentCategory;
  // Note: Account filter is applied in repo, not stored here directly unless needed for UI

  ExpenseListBloc({
    required GetExpensesUseCase getExpensesUseCase,
    required DeleteExpenseUseCase deleteExpenseUseCase,
    required Stream<DataChangedEvent> dataChangeStream, // Inject stream
  })  : _getExpensesUseCase = getExpensesUseCase,
        _deleteExpenseUseCase = deleteExpenseUseCase,
        super(ExpenseListInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<FilterExpenses>(_onFilterExpenses);
    on<DeleteExpenseRequested>(_onDeleteExpenseRequested);
    on<_DataChanged>(_onDataChanged); // Handler for internal event

    // Subscribe to the data change stream
    _dataChangeSubscription = dataChangeStream.listen((event) {
      // Expense list only needs refresh if Expenses change directly
      if (event.type == DataChangeType.expense) {
        debugPrint(
            "[ExpenseListBloc] Received relevant DataChangedEvent: $event. Adding _DataChanged event.");
        add(const _DataChanged());
      }
    });
    debugPrint("[ExpenseListBloc] Initialized and subscribed to data changes.");
  }

  // Internal event handler to trigger reload
  Future<void> _onDataChanged(
      _DataChanged event, Emitter<ExpenseListState> emit) async {
    debugPrint(
        "[ExpenseListBloc] Handling _DataChanged event. Dispatching LoadExpenses.");
    // Trigger reload, force update to reflect changes immediately
    add(const LoadExpenses(forceReload: true));
  }

  // Handler for loading expenses (initial load or refresh)
  Future<void> _onLoadExpenses(
      LoadExpenses event, Emitter<ExpenseListState> emit) async {
    debugPrint(
        "[ExpenseListBloc] Received LoadExpenses event. ForceReload: ${event.forceReload}");
    // Show loading only if not already loaded or if forced
    if (state is! ExpenseListLoaded || event.forceReload) {
      if (state is! ExpenseListLoaded) {
        debugPrint(
            "[ExpenseListBloc] Current state is not Loaded. Emitting ExpenseListLoading.");
        emit(ExpenseListLoading());
      } else {
        debugPrint(
            "[ExpenseListBloc] Force reload requested. Refreshing data.");
        // Optionally emit a Refreshing state here if needed
      }
    } else {
      debugPrint(
          "[ExpenseListBloc] Current state is Loaded and no force reload. Refreshing data without emitting Loading.");
    }

    // Use the stored filters for reloading/refreshing
    final params = GetExpensesParams(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      category: _currentCategory,
      // accountId filter is applied in repo/usecase if needed, not stored here
    );
    debugPrint(
        "[ExpenseListBloc] Calling GetExpensesUseCase with params: Start=${params.startDate}, End=${params.endDate}, Cat=${params.category}");

    try {
      final result = await _getExpensesUseCase(params);
      debugPrint(
          "[ExpenseListBloc] GetExpensesUseCase returned. Result isLeft: ${result.isLeft()}");

      result.fold(
        // On Failure
        (failure) {
          debugPrint(
              "[ExpenseListBloc] Emitting ExpenseListError: ${failure.message}");
          emit(ExpenseListError(_mapFailureToMessage(failure)));
        },
        // On Success
        (expenses) {
          debugPrint(
              "[ExpenseListBloc] Emitting ExpenseListLoaded with ${expenses.length} expenses.");
          emit(ExpenseListLoaded(
            expenses: expenses,
            filterStartDate:
                _currentStartDate, // Pass current filters to the state
            filterEndDate: _currentEndDate,
            filterCategory: _currentCategory,
          ));
        },
      );
    } catch (e, s) {
      debugPrint(
          "[ExpenseListBloc] *** CRITICAL ERROR in _onLoadExpenses: $e\n$s");
      emit(ExpenseListError(
          "An unexpected error occurred loading expenses: $e"));
    } finally {
      debugPrint(
          "[ExpenseListBloc] Finished processing LoadExpenses event handler.");
    }
  }

  // Handler for applying new filters
  Future<void> _onFilterExpenses(
      FilterExpenses event, Emitter<ExpenseListState> emit) async {
    debugPrint("[ExpenseListBloc] Received FilterExpenses event.");
    emit(ExpenseListLoading()); // Show loading indicator while filtering

    // Update the stored filters
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _currentCategory = event.category;
    debugPrint(
        "[ExpenseListBloc] Filters updated: Start=$_currentStartDate, End=$_currentEndDate, Cat=$_currentCategory");

    // Trigger load with new filters (no need to force reload, Loading state handles it)
    add(const LoadExpenses());
  }

  // Handler for requesting deletion of an expense
  Future<void> _onDeleteExpenseRequested(
      DeleteExpenseRequested event, Emitter<ExpenseListState> emit) async {
    debugPrint(
        "[ExpenseListBloc] Received DeleteExpenseRequested for ID: ${event.expenseId}");
    final currentState =
        state; // Capture the current state before async operation

    if (currentState is ExpenseListLoaded) {
      debugPrint(
          "[ExpenseListBloc] Current state is Loaded. Proceeding with optimistic delete.");
      // Optimistic UI Update: Remove item immediately
      final optimisticList = currentState.expenses
          .where((exp) => exp.id != event.expenseId)
          .toList();
      debugPrint(
          "[ExpenseListBloc] Optimistic list size: ${optimisticList.length}. Emitting updated ExpenseListLoaded.");
      // Emit updated state with item removed
      emit(ExpenseListLoaded(
        expenses: optimisticList,
        filterStartDate: currentState.filterStartDate,
        filterEndDate: currentState.filterEndDate,
        filterCategory: currentState.filterCategory,
      ));

      try {
        // Attempt deletion via use case
        final result =
            await _deleteExpenseUseCase(DeleteExpenseParams(event.expenseId));
        debugPrint(
            "[ExpenseListBloc] DeleteExpenseUseCase returned. Result isLeft: ${result.isLeft()}");

        result.fold(
          // On Failure (Deletion failed)
          (failure) {
            debugPrint(
                "[ExpenseListBloc] Deletion failed: ${failure.message}. Reverting UI and emitting Error.");
            // Revert the optimistic update by emitting the original state
            emit(currentState);
            // Also emit an error state to potentially show a message
            emit(ExpenseListError(
                "Failed to delete: ${_mapFailureToMessage(failure)}"));
            // Optionally trigger a forced reload for consistency:
            // add(LoadExpenses(forceReload: true));
          },
          // On Success (Deletion successful)
          (_) {
            debugPrint(
                "[ExpenseListBloc] Deletion successful (Optimistic UI). Publishing DataChangedEvent.");
            // Publish event so other Blocs (Dashboard, Accounts, Summary) can react
            publishDataChangedEvent(
                type: DataChangeType.expense, reason: DataChangeReason.deleted);
          },
        );
      } catch (e, s) {
        debugPrint(
            "[ExpenseListBloc] *** CRITICAL ERROR in _onDeleteExpenseRequested: $e\n$s");
        // Revert optimistic update on unexpected error
        emit(currentState);
        emit(ExpenseListError(
            "An unexpected error occurred during deletion: $e"));
      }
    } else {
      debugPrint(
          "[ExpenseListBloc] Delete requested but state is not ExpenseListLoaded. Ignoring.");
    }
    debugPrint("[ExpenseListBloc] Finished processing DeleteExpenseRequested.");
  }

  // Helper to convert Failures to user-readable messages
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'Database Error: ${failure.message}';
      case ValidationFailure:
        return failure
            .message; // Handle validation failures if use case returns them
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }

  // Cancel stream subscription when BLoC is closed
  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    debugPrint("[ExpenseListBloc] Canceled data change subscription.");
    return super.close();
  }
}
