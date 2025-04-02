import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/get_expenses.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl helper & publish
import 'package:expense_tracker/core/events/data_change_event.dart'; // Import event

part 'expense_list_event.dart';
part 'expense_list_state.dart';

class ExpenseListBloc extends Bloc<ExpenseListEvent, ExpenseListState> {
  final GetExpensesUseCase _getExpensesUseCase;
  final DeleteExpenseUseCase _deleteExpenseUseCase;
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  // Store current filters to re-apply on refresh
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  String? _currentCategory;
  String?
      _currentAccountId; // Filter applied in repo, store for state consistency

  ExpenseListBloc({
    required GetExpensesUseCase getExpensesUseCase,
    required DeleteExpenseUseCase deleteExpenseUseCase,
    required Stream<DataChangedEvent> dataChangeStream,
  })  : _getExpensesUseCase = getExpensesUseCase,
        _deleteExpenseUseCase = deleteExpenseUseCase,
        super(ExpenseListInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<FilterExpenses>(_onFilterExpenses);
    on<DeleteExpenseRequested>(_onDeleteExpenseRequested);
    on<_DataChanged>(_onDataChanged);

    _dataChangeSubscription = dataChangeStream.listen((event) {
      // Expense list needs refresh if Expenses or Settings (currency) change
      if (event.type == DataChangeType.expense ||
          event.type == DataChangeType.settings) {
        log.info(
            "[ExpenseListBloc] Received relevant DataChangedEvent: $event. Triggering reload.");
        add(const _DataChanged());
      }
    }, onError: (error, stackTrace) {
      log.severe("[ExpenseListBloc] Error in dataChangeStream listener" +
          error +
          stackTrace);
    });
    log.info("[ExpenseListBloc] Initialized and subscribed to data changes.");
  }

  // Internal event handler to trigger reload
  Future<void> _onDataChanged(
      _DataChanged event, Emitter<ExpenseListState> emit) async {
    log.info(
        "[ExpenseListBloc] Handling _DataChanged event. Dispatching LoadExpenses(forceReload: true).");
    // Always force reload on data change
    add(const LoadExpenses(forceReload: true));
  }

  Future<void> _onLoadExpenses(
      LoadExpenses event, Emitter<ExpenseListState> emit) async {
    log.info(
        "[ExpenseListBloc] Received LoadExpenses event (forceReload: ${event.forceReload}). Current state: ${state.runtimeType}");

    if (state is! ExpenseListLoaded || event.forceReload) {
      emit(ExpenseListLoading(isReloading: state is ExpenseListLoaded));
      log.info(
          "[ExpenseListBloc] Emitting ExpenseListLoading (isReloading: ${state is ExpenseListLoaded}).");
    } else {
      log.info(
          "[ExpenseListBloc] State is Loaded and no force reload. Refreshing data silently.");
    }

    // Use the stored filters for reloading/refreshing
    final params = GetExpensesParams(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      category: _currentCategory,
      accountId: _currentAccountId,
    );
    log.info(
        "[ExpenseListBloc] Calling GetExpensesUseCase with params: AccID=${params.accountId}, Start=${params.startDate}, End=${params.endDate}, Cat=${params.category}");

    try {
      final result = await _getExpensesUseCase(params);
      log.info(
          "[ExpenseListBloc] GetExpensesUseCase returned. isLeft: ${result.isLeft()}");

      result.fold(
        (failure) {
          log.warning(
              "[ExpenseListBloc] Load failed: ${failure.message}. Emitting ExpenseListError.");
          emit(ExpenseListError(_mapFailureToMessage(failure)));
        },
        (expenses) {
          log.info(
              "[ExpenseListBloc] Load successful. Emitting ExpenseListLoaded with ${expenses.length} expenses.");
          emit(ExpenseListLoaded(
            expenses: expenses,
            filterStartDate: _currentStartDate,
            filterEndDate: _currentEndDate,
            filterCategory: _currentCategory,
            filterAccountId: _currentAccountId,
          ));
        },
      );
    } catch (e, s) {
      log.severe("[ExpenseListBloc] Unexpected error in _onLoadExpenses$e");
      emit(ExpenseListError(
          "An unexpected error occurred loading expenses: ${e.toString()}"));
    }
  }

  Future<void> _onFilterExpenses(
      FilterExpenses event, Emitter<ExpenseListState> emit) async {
    log.info("[ExpenseListBloc] Received FilterExpenses event.");

    // Update the stored filters
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _currentCategory = event.category;
    _currentAccountId = event.accountId; // Store account filter if provided
    log.info(
        "[ExpenseListBloc] Filters updated: AccID=$_currentAccountId, Start=$_currentStartDate, End=$_currentEndDate, Cat=$_currentCategory");

    // Trigger load with new filters (LoadExpenses will handle emitting Loading state)
    add(const LoadExpenses(
        forceReload: true)); // Force reload to apply filters immediately
  }

  Future<void> _onDeleteExpenseRequested(
      DeleteExpenseRequested event, Emitter<ExpenseListState> emit) async {
    log.info(
        "[ExpenseListBloc] Received DeleteExpenseRequested for ID: ${event.expenseId}");
    final currentState = state;

    if (currentState is ExpenseListLoaded) {
      log.info(
          "[ExpenseListBloc] Current state is Loaded. Performing optimistic delete.");
      // Optimistic UI Update
      final optimisticList = currentState.expenses
          .where((exp) => exp.id != event.expenseId)
          .toList();
      log.info(
          "[ExpenseListBloc] Optimistic list size: ${optimisticList.length}. Emitting updated ExpenseListLoaded.");
      // Emit updated state with item removed
      emit(ExpenseListLoaded(
        expenses: optimisticList,
        filterStartDate: currentState.filterStartDate,
        filterEndDate: currentState.filterEndDate,
        filterCategory: currentState.filterCategory,
        filterAccountId: currentState.filterAccountId,
      ));

      try {
        final result =
            await _deleteExpenseUseCase(DeleteExpenseParams(event.expenseId));
        log.info(
            "[ExpenseListBloc] DeleteExpenseUseCase returned. isLeft: ${result.isLeft()}");

        result.fold(
          (failure) {
            log.warning(
                "[ExpenseListBloc] Deletion failed: ${failure.message}. Reverting UI and emitting Error.");
            // Revert the optimistic update
            emit(currentState);
            // Emit an error state *after* reverting
            emit(ExpenseListError(_mapFailureToMessage(failure,
                context: "Failed to delete expense")));
          },
          (_) {
            log.info(
                "[ExpenseListBloc] Deletion successful. Publishing DataChangedEvent.");
            // Publish event so other Blocs can react
            publishDataChangedEvent(
                type: DataChangeType.expense, reason: DataChangeReason.deleted);
          },
        );
      } catch (e, s) {
        // ignore: prefer_interpolation_to_compose_strings
        log.severe(
            "[ExpenseListBloc] Unexpected error in _onDeleteExpenseRequested for ID ${event.expenseId}" +
                e.toString() +
                s.toString());
        emit(currentState); // Revert optimistic update
        emit(ExpenseListError(
            "An unexpected error occurred during deletion: ${e.toString()}"));
      }
    } else {
      log.warning(
          "[ExpenseListBloc] Delete requested but state is not ExpenseListLoaded. Ignoring.");
    }
  }

  String _mapFailureToMessage(Failure failure,
      {String context = "An error occurred"}) {
    log.warning(
        "[ExpenseListBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
    String specificMessage;
    switch (failure.runtimeType) {
      case CacheFailure:
        specificMessage = 'Database Error: ${failure.message}';
        break;
      case ValidationFailure:
        specificMessage = failure.message;
        break;
      case UnexpectedFailure:
        specificMessage = 'An unexpected error occurred. Please try again.';
        break;
      default:
        specificMessage = failure.message.isNotEmpty
            ? failure.message
            : 'An unknown error occurred.';
        break;
    }
    return "$context: $specificMessage";
  }

  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    log.info(
        "[ExpenseListBloc] Canceled data change subscription and closing.");
    return super.close();
  }
}
