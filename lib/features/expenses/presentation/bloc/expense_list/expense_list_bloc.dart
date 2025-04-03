import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/get_expenses.dart';
import 'package:expense_tracker/features/categories/domain/usecases/apply_category_to_batch.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';

part 'expense_list_event.dart';
part 'expense_list_state.dart';

class ExpenseListBloc extends Bloc<ExpenseListEvent, ExpenseListState> {
  final GetExpensesUseCase _getExpensesUseCase;
  final DeleteExpenseUseCase _deleteExpenseUseCase;
  final ApplyCategoryToBatchUseCase _applyCategoryToBatchUseCase;
  final SaveUserCategorizationHistoryUseCase _saveUserHistoryUseCase;
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  String? _currentCategory;
  String? _currentAccountId;

  ExpenseListBloc({
    required GetExpensesUseCase getExpensesUseCase,
    required DeleteExpenseUseCase deleteExpenseUseCase,
    required ApplyCategoryToBatchUseCase applyCategoryToBatchUseCase,
    required SaveUserCategorizationHistoryUseCase saveUserHistoryUseCase,
    required Stream<DataChangedEvent> dataChangeStream,
  })  : _getExpensesUseCase = getExpensesUseCase,
        _deleteExpenseUseCase = deleteExpenseUseCase,
        _applyCategoryToBatchUseCase = applyCategoryToBatchUseCase,
        _saveUserHistoryUseCase = saveUserHistoryUseCase,
        super(const ExpenseListInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<FilterExpenses>(_onFilterExpenses);
    on<DeleteExpenseRequested>(_onDeleteExpenseRequested);
    on<ToggleBatchEditMode>(_onToggleBatchEditMode);
    on<SelectExpense>(_onSelectExpense);
    on<ApplyBatchCategory>(_onApplyBatchCategory);
    on<UpdateSingleExpenseCategory>(_onUpdateSingleExpenseCategory);
    on<UserCategorizedExpense>(_onUserCategorizedExpense);
    on<_DataChanged>(_onDataChanged); // Ensure handler is registered

    _dataChangeSubscription = dataChangeStream.listen((event) {
      if (event.type == DataChangeType.expense ||
          event.type == DataChangeType.category ||
          event.type == DataChangeType.settings) {
        log.info(
            "[ExpenseListBloc] Received relevant DataChangedEvent: $event. Triggering reload.");
        add(const _DataChanged()); // Dispatch internal event
      }
    }, onError: (error, stackTrace) {
      log.severe(
          "[ExpenseListBloc] Error in dataChangeStream listener: $error");
    });
    log.info("[ExpenseListBloc] Initialized and subscribed to data changes.");
  }

  // --- ADDED Missing Handler ---
  // Internal event handler to trigger reload
  Future<void> _onDataChanged(
      _DataChanged event, Emitter<ExpenseListState> emit) async {
    // Only reload if the state is not already loading to avoid concurrent loads
    if (state is! ExpenseListLoading) {
      log.info(
          "[ExpenseListBloc] Handling _DataChanged event. Dispatching LoadExpenses(forceReload: true).");
      add(const LoadExpenses(forceReload: true));
    } else {
      log.info(
          "[ExpenseListBloc] Handling _DataChanged event. State is already loading, skipping reload dispatch.");
    }
  }
  // --- END ADDED ---

  // ... (rest of the handlers: _onLoadExpenses, _onFilterExpenses, etc. remain as corrected before) ...
  Future<void> _onLoadExpenses(
      LoadExpenses event, Emitter<ExpenseListState> emit) async {
    log.info(
        "[ExpenseListBloc] Received LoadExpenses event (forceReload: ${event.forceReload}). Current state: ${state.runtimeType}");
    final currentState = state;
    final bool wasInBatchEdit =
        currentState is ExpenseListLoaded && currentState.isInBatchEditMode;
    final Set<String> previousSelection = currentState is ExpenseListLoaded
        ? currentState.selectedTransactionIds
        : {};

    if (currentState is! ExpenseListLoaded || event.forceReload) {
      emit(ExpenseListLoading(isReloading: currentState is ExpenseListLoaded));
      log.info(
          "[ExpenseListBloc] Emitting ExpenseListLoading (isReloading: ${currentState is ExpenseListLoaded}).");
    }

    final params = GetExpensesParams(
        startDate: _currentStartDate,
        endDate: _currentEndDate,
        category: _currentCategory,
        accountId: _currentAccountId);
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
              "[ExpenseListBloc] Load successful. Emitting ExpenseListLoaded with ${expenses.length} expenses. Preserving batch mode: $wasInBatchEdit");
          final validSelection = previousSelection
              .where((id) => expenses.any((exp) => exp.id == id))
              .toSet();
          emit(ExpenseListLoaded(
            expenses: expenses,
            filterStartDate: _currentStartDate,
            filterEndDate: _currentEndDate,
            filterCategory: _currentCategory,
            filterAccountId: _currentAccountId,
            isInBatchEditMode: wasInBatchEdit,
            selectedTransactionIds: validSelection,
          ));
        },
      );
    } catch (e, s) {
      log.severe("[ExpenseListBloc] Unexpected error in _onLoadExpenses");
      emit(ExpenseListError(
          "An unexpected error occurred loading expenses: ${e.toString()}"));
    }
  }

  Future<void> _onFilterExpenses(
      FilterExpenses event, Emitter<ExpenseListState> emit) async {
    log.info("[ExpenseListBloc] Received FilterExpenses event.");
    if (state is ExpenseListLoaded) {
      emit((state as ExpenseListLoaded).copyWith(
        isInBatchEditMode: false,
        selectedTransactionIds: {},
      ));
    }
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _currentCategory = event.category;
    _currentAccountId = event.accountId;
    log.info(
        "[ExpenseListBloc] Filters updated: AccID=$_currentAccountId, Start=$_currentStartDate, End=$_currentEndDate, Cat=$_currentCategory. Triggering load.");
    add(const LoadExpenses(forceReload: true));
  }

  Future<void> _onDeleteExpenseRequested(
      DeleteExpenseRequested event, Emitter<ExpenseListState> emit) async {
    log.info(
        "[ExpenseListBloc] Received DeleteExpenseRequested for ID: ${event.expenseId}");
    final currentState = state;
    if (currentState is ExpenseListLoaded) {
      log.info(
          "[ExpenseListBloc] Current state is Loaded. Performing optimistic delete.");
      final optimisticList =
          currentState.items.where((exp) => exp.id != event.expenseId).toList();
      final updatedSelection =
          Set<String>.from(currentState.selectedTransactionIds)
            ..remove(event.expenseId);
      log.info(
          "[ExpenseListBloc] Optimistic list size: ${optimisticList.length}. Emitting updated ExpenseListLoaded.");
      emit(currentState.copyWith(
          expenses: optimisticList, selectedTransactionIds: updatedSelection));

      try {
        final result =
            await _deleteExpenseUseCase(DeleteExpenseParams(event.expenseId));
        log.info(
            "[ExpenseListBloc] DeleteExpenseUseCase returned. isLeft: ${result.isLeft()}");
        result.fold(
          (failure) {
            log.warning(
                "[ExpenseListBloc] Deletion failed: ${failure.message}. Reverting UI and emitting Error.");
            emit(currentState);
            emit(ExpenseListError(_mapFailureToMessage(failure,
                context: "Failed to delete expense")));
          },
          (_) {
            log.info(
                "[ExpenseListBloc] Deletion successful. Publishing DataChangedEvent.");
            publishDataChangedEvent(
                type: DataChangeType.expense, reason: DataChangeReason.deleted);
          },
        );
      } catch (e, s) {
        log.severe(
            "[ExpenseListBloc] Unexpected error in _onDeleteExpenseRequested for ID ${event.expenseId}");
        emit(currentState);
        emit(ExpenseListError(
            "An unexpected error occurred during deletion: ${e.toString()}"));
      }
    } else {
      log.warning(
          "[ExpenseListBloc] Delete requested but state is not ExpenseListLoaded. Ignoring.");
    }
  }

  void _onToggleBatchEditMode(
      ToggleBatchEditMode event, Emitter<ExpenseListState> emit) {
    if (state is ExpenseListLoaded) {
      final currentLoadedState = state as ExpenseListLoaded;
      final bool newMode = !currentLoadedState.isInBatchEditMode;
      log.info("[ExpenseListBloc] Toggling Batch Edit Mode to: $newMode");
      emit(currentLoadedState.copyWith(
        isInBatchEditMode: newMode,
        selectedTransactionIds:
            newMode ? currentLoadedState.selectedTransactionIds : {},
      ));
    } else {
      log.warning(
          "[ExpenseListBloc] ToggleBatchEditMode ignored: State is not Loaded.");
    }
  }

  void _onSelectExpense(SelectExpense event, Emitter<ExpenseListState> emit) {
    if (state is ExpenseListLoaded) {
      final currentLoadedState = state as ExpenseListLoaded;
      if (!currentLoadedState.isInBatchEditMode) {
        log.warning(
            "[ExpenseListBloc] SelectExpense ignored: Not in Batch Edit Mode.");
        return;
      }
      final currentSelection = currentLoadedState.selectedTransactionIds;
      final newSelection = Set<String>.from(currentSelection);
      if (newSelection.contains(event.expenseId)) {
        newSelection.remove(event.expenseId);
        log.fine("[ExpenseListBloc] Deselected expense ID: ${event.expenseId}");
      } else {
        newSelection.add(event.expenseId);
        log.fine("[ExpenseListBloc] Selected expense ID: ${event.expenseId}");
      }
      emit(currentLoadedState.copyWith(selectedTransactionIds: newSelection));
    } else {
      log.warning(
          "[ExpenseListBloc] SelectExpense ignored: State is not Loaded.");
    }
  }

  Future<void> _onApplyBatchCategory(
      ApplyBatchCategory event, Emitter<ExpenseListState> emit) async {
    if (state is ExpenseListLoaded) {
      final currentLoadedState = state as ExpenseListLoaded;
      if (!currentLoadedState.isInBatchEditMode ||
          currentLoadedState.selectedTransactionIds.isEmpty) {
        log.warning(
            "[ExpenseListBloc] ApplyBatchCategory ignored: Not in batch mode or no items selected.");
        return;
      }
      log.info(
          "[ExpenseListBloc] Applying category '${event.categoryId}' to ${currentLoadedState.selectedTransactionIds.length} expenses.");

      final params = ApplyCategoryToBatchParams(
        transactionIds: currentLoadedState.selectedTransactionIds.toList(),
        categoryId: event.categoryId,
        transactionType: TransactionType.expense,
      );
      final result = await _applyCategoryToBatchUseCase(params);

      result.fold((failure) {
        log.warning(
            "[ExpenseListBloc] ApplyBatchCategory failed: ${failure.message}");
        emit(ExpenseListError(_mapFailureToMessage(failure,
            context: "Failed to apply category to batch")));
        emit(currentLoadedState);
      }, (_) {
        log.info(
            "[ExpenseListBloc] ApplyBatchCategory successful. Exiting batch mode and reloading.");
        emit(currentLoadedState
            .copyWith(isInBatchEditMode: false, selectedTransactionIds: {}));
        publishDataChangedEvent(
            type: DataChangeType.expense, reason: DataChangeReason.updated);
      });
    } else {
      log.warning(
          "[ExpenseListBloc] ApplyBatchCategory ignored: State is not Loaded.");
    }
  }

  Future<void> _onUpdateSingleExpenseCategory(
      UpdateSingleExpenseCategory event, Emitter<ExpenseListState> emit) async {
    if (state is ExpenseListLoaded) {
      final currentLoadedState = state as ExpenseListLoaded;
      log.info(
          "[ExpenseListBloc] Updating single expense ${event.expenseId} to category ${event.categoryId}. Status: ${event.status.name}");

      final repo = sl<ExpenseRepository>();
      final result = await repo.updateExpenseCategorization(
        event.expenseId,
        event.categoryId,
        event.status,
        event.confidence,
      );

      result.fold((failure) {
        log.warning(
            "[ExpenseListBloc] UpdateSingleExpenseCategory failed: ${failure.message}");
        emit(ExpenseListError(_mapFailureToMessage(failure,
            context: "Failed to update category")));
        emit(currentLoadedState);
      }, (_) {
        log.info(
            "[ExpenseListBloc] UpdateSingleExpenseCategory successful in repo. DataChanged event will reload list.");
        publishDataChangedEvent(
            type: DataChangeType.expense, reason: DataChangeReason.updated);
      });
    } else {
      log.warning(
          "[ExpenseListBloc] UpdateSingleExpenseCategory ignored: State is not Loaded.");
    }
  }

  Future<void> _onUserCategorizedExpense(
      UserCategorizedExpense event, Emitter<ExpenseListState> emit) async {
    if (state is! ExpenseListLoaded) {
      log.warning(
          "[ExpenseListBloc] UserCategorizedExpense ignored: State is not Loaded.");
      return;
    }
    log.info(
        "[ExpenseListBloc] Handling UserCategorizedExpense for ID: ${event.expenseId}, Category: ${event.selectedCategory.name}");

    // 1. Save User History
    final historyParams = SaveUserCategorizationHistoryParams(
        transactionData: event.matchData,
        selectedCategory: event.selectedCategory);
    _saveUserHistoryUseCase(historyParams).then((result) {
      result.fold(
          (failure) => log.warning(
              "[ExpenseListBloc] Failed to save user history: ${failure.message}"),
          (_) => log.info(
              "[ExpenseListBloc] User history saved successfully for rule based on transaction ${event.expenseId}"));
    });

    // 2. Update the transaction status/category
    add(UpdateSingleExpenseCategory(
        expenseId: event.expenseId,
        categoryId: event.selectedCategory.id,
        status: CategorizationStatus.categorized,
        confidence: 1.0));
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
