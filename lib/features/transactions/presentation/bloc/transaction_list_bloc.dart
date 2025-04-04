import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/enums.dart'; // CategorizationStatus
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
// Import ApplyCategoryToBatchUseCase (Assuming it's refactored to use the primary TransactionType)
import 'package:expense_tracker/features/categories/domain/usecases/apply_category_to_batch.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
// Import the primary TransactionType enum and related entity/usecase
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:expense_tracker/main.dart';
// Import repositories for direct updates
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';

part 'transaction_list_event.dart';
part 'transaction_list_state.dart';

class TransactionListBloc
    extends Bloc<TransactionListEvent, TransactionListState> {
  final GetTransactionsUseCase _getTransactionsUseCase;
  final DeleteExpenseUseCase _deleteExpenseUseCase;
  final DeleteIncomeUseCase _deleteIncomeUseCase;
  final ApplyCategoryToBatchUseCase _applyCategoryToBatchUseCase;
  final SaveUserCategorizationHistoryUseCase _saveUserHistoryUseCase;
  final ExpenseRepository _expenseRepository;
  final IncomeRepository _incomeRepository;

  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  TransactionListBloc({
    required GetTransactionsUseCase getTransactionsUseCase,
    required DeleteExpenseUseCase deleteExpenseUseCase,
    required DeleteIncomeUseCase deleteIncomeUseCase,
    required ApplyCategoryToBatchUseCase applyCategoryToBatchUseCase,
    required SaveUserCategorizationHistoryUseCase saveUserHistoryUseCase,
    required ExpenseRepository expenseRepository,
    required IncomeRepository incomeRepository,
    required Stream<DataChangedEvent> dataChangeStream,
  })  : _getTransactionsUseCase = getTransactionsUseCase,
        _deleteExpenseUseCase = deleteExpenseUseCase,
        _deleteIncomeUseCase = deleteIncomeUseCase,
        _applyCategoryToBatchUseCase = applyCategoryToBatchUseCase,
        _saveUserHistoryUseCase = saveUserHistoryUseCase,
        _expenseRepository = expenseRepository,
        _incomeRepository = incomeRepository,
        super(const TransactionListState()) {
    // Register Event Handlers
    on<LoadTransactions>(_onLoadTransactions);
    on<FilterChanged>(_onFilterChanged);
    on<SortChanged>(_onSortChanged);
    on<SearchChanged>(_onSearchChanged);
    on<ToggleBatchEdit>(_onToggleBatchEdit);
    on<SelectTransaction>(_onSelectTransaction);
    on<ApplyBatchCategory>(_onApplyBatchCategory);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<UserCategorizedTransaction>(_onUserCategorizedTransaction);
    on<_DataChanged>(_onDataChanged);

    // Subscribe to Data Change Stream
    _dataChangeSubscription = dataChangeStream.listen((event) {
      // Reload if relevant data changes
      if (event.type == DataChangeType.expense ||
          event.type == DataChangeType.income ||
          event.type == DataChangeType.category ||
          event.type == DataChangeType.account ||
          event.type == DataChangeType.settings) {
        log.info(
            "[TransactionListBloc] Relevant DataChangedEvent: $event. Triggering reload.");
        add(const _DataChanged()); // Use internal event to trigger reload
      }
    }, onError: (error, stackTrace) {
      log.severe(
          "[TransactionListBloc] Error in dataChangeStream listener: $error");
    });
    log.info(
        "[TransactionListBloc] Initialized and subscribed to data changes.");
  }

  // --- Event Handlers ---

  Future<void> _onLoadTransactions(
      LoadTransactions event, Emitter<TransactionListState> emit) async {
    log.info(
        "[TransactionListBloc] LoadTransactions triggered. ForceReload: ${event.forceReload}");
    // Only show loading state if not already loaded or forced
    if (state.status != ListStatus.success || event.forceReload) {
      emit(state.copyWith(
        status: state.status == ListStatus.success
            ? ListStatus.reloading
            : ListStatus.loading,
        clearErrorMessage: true, // Clear previous errors on load attempt
      ));
    } else {
      log.info(
          "[TransactionListBloc] Already loaded, skipping explicit loading state.");
    }

    // Prepare parameters from current state
    final params = GetTransactionsParams(
      startDate: state.startDate,
      endDate: state.endDate,
      categoryId: state.categoryId,
      accountId: state.accountId,
      transactionType: state.transactionType,
      searchTerm: state.searchTerm,
      sortBy: state.sortBy,
      sortDirection: state.sortDirection,
    );

    // Call the UseCase
    final result = await _getTransactionsUseCase(params);

    // Process the result
    result.fold((failure) {
      log.warning("[TransactionListBloc] Load failed: ${failure.message}");
      emit(state.copyWith(
          status: ListStatus.error,
          errorMessage: _mapFailureToMessage(failure)));
    }, (transactions) {
      log.info(
          "[TransactionListBloc] Load successful with ${transactions.length} transactions.");
      // Preserve selection only if batch mode is active
      final validSelection = state.isInBatchEditMode
          ? state.selectedTransactionIds
              .where((id) => transactions.any((txn) => txn.id == id))
              .toSet()
          : <String>{}; // Clear selection if not in batch mode

      emit(state.copyWith(
          status: ListStatus.success,
          transactions: transactions,
          selectedTransactionIds: validSelection,
          // Clear error on successful load
          clearErrorMessage: true));
    });
  }

  Future<void> _onFilterChanged(
      FilterChanged event, Emitter<TransactionListState> emit) async {
    log.info("[TransactionListBloc] FilterChanged triggered.");
    // Update state with new filters and exit batch mode
    emit(state.copyWith(
      startDate: event.startDate, endDate: event.endDate,
      categoryId: event.categoryId,
      accountId: event.accountId, transactionType: event.transactionType,
      isInBatchEditMode: false, selectedTransactionIds: {},
      clearStartDate: event.startDate == null && state.startDate != null,
      clearEndDate: event.endDate == null && state.endDate != null,
      clearCategoryId: event.categoryId == null && state.categoryId != null,
      clearAccountId: event.accountId == null && state.accountId != null,
      clearTransactionType:
          event.transactionType == null && state.transactionType != null,
      clearErrorMessage: true, // Clear error when filters change
    ));
    // Trigger reload with new filters
    add(const LoadTransactions(forceReload: true));
  }

  Future<void> _onSortChanged(
      SortChanged event, Emitter<TransactionListState> emit) async {
    log.info(
        "[TransactionListBloc] SortChanged triggered: ${event.sortBy}.${event.sortDirection}");
    // Update state with new sort order and exit batch mode
    emit(state.copyWith(
      sortBy: event.sortBy, sortDirection: event.sortDirection,
      isInBatchEditMode: false, selectedTransactionIds: {},
      clearErrorMessage: true, // Clear error when sort changes
    ));
    // Trigger reload with new sort order
    add(const LoadTransactions(forceReload: true));
  }

  Future<void> _onSearchChanged(
      SearchChanged event, Emitter<TransactionListState> emit) async {
    log.info(
        "[TransactionListBloc] SearchChanged triggered: '${event.searchTerm}'");
    // Update state with new search term and exit batch mode
    emit(state.copyWith(
      searchTerm: event.searchTerm,
      clearSearchTerm: event.searchTerm == null || event.searchTerm!.isEmpty,
      isInBatchEditMode: false, selectedTransactionIds: {},
      clearErrorMessage: true, // Clear error when search changes
    ));
    // Trigger reload with new search term
    add(const LoadTransactions(forceReload: true));
  }

  void _onToggleBatchEdit(
      ToggleBatchEdit event, Emitter<TransactionListState> emit) {
    log.info("[TransactionListBloc] ToggleBatchEdit triggered.");
    final newMode = !state.isInBatchEditMode;
    emit(state.copyWith(
      isInBatchEditMode: newMode,
      // Clear selection when exiting batch mode
      selectedTransactionIds: newMode ? state.selectedTransactionIds : {},
      clearErrorMessage: true, // Clear any previous errors
    ));
  }

  void _onSelectTransaction(
      SelectTransaction event, Emitter<TransactionListState> emit) {
    if (!state.isInBatchEditMode) {
      log.warning(
          "[TransactionListBloc] SelectTransaction ignored: Not in batch edit mode.");
      return;
    }
    log.fine("[TransactionListBloc] SelectTransaction: ${event.transactionId}");
    final currentSelection = state.selectedTransactionIds;
    final newSelection = Set<String>.from(currentSelection);
    if (newSelection.contains(event.transactionId)) {
      newSelection.remove(event.transactionId);
    } else {
      newSelection.add(event.transactionId);
    }
    // Emit state update with modified selection
    emit(state.copyWith(selectedTransactionIds: newSelection));
  }

  Future<void> _onApplyBatchCategory(
      ApplyBatchCategory event, Emitter<TransactionListState> emit) async {
    if (!state.isInBatchEditMode || state.selectedTransactionIds.isEmpty) {
      log.warning(
          "[TransactionListBloc] ApplyBatchCategory ignored: Not in batch mode or no selection.");
      return;
    }
    log.info(
        "[TransactionListBloc] ApplyBatchCategory: CatID=${event.categoryId}, Count=${state.selectedTransactionIds.length}");

    emit(
        state.copyWith(status: ListStatus.reloading)); // Show loading indicator

    final List<String> expenseIds = [];
    final List<String> incomeIds = [];
    final currentTransactions = state.transactions; // Cache list locally

    for (final id in state.selectedTransactionIds) {
      final txn = currentTransactions.firstWhere((t) => t.id == id, orElse: () {
        log.severe(
            "[TransactionListBloc] CRITICAL: Selected ID $id not found in current transaction state during batch apply!");
        throw Exception(
            "Selected ID $id not found in state during batch apply");
      });
      // Use the primary TransactionType enum for comparison
      if (txn.type == TransactionType.expense) {
        expenseIds.add(id);
      } else if (txn.type == TransactionType.income) {
        incomeIds.add(id);
      }
    }

    Failure? batchFailure;

    // Apply to Expenses if any are selected
    if (expenseIds.isNotEmpty) {
      // Use ApplyCategoryToBatchParams with the primary TransactionType enum
      final expenseParams = ApplyCategoryToBatchParams(
        transactionIds: expenseIds,
        categoryId: event.categoryId,
        transactionType: TransactionType.expense, // Use primary enum
      );
      final expenseResult = await _applyCategoryToBatchUseCase(expenseParams);
      expenseResult.fold((f) => batchFailure = f, (_) {});
      log.fine(
          "[TransactionListBloc] Expense batch apply result: ${expenseResult.isRight()}");
    }

    // Apply to Income if any are selected and expense part succeeded
    if (batchFailure == null && incomeIds.isNotEmpty) {
      final incomeParams = ApplyCategoryToBatchParams(
        transactionIds: incomeIds,
        categoryId: event.categoryId,
        transactionType: TransactionType.income, // Use primary enum
      );
      final incomeResult = await _applyCategoryToBatchUseCase(incomeParams);
      incomeResult.fold((f) => batchFailure = f, (_) {});
      log.fine(
          "[TransactionListBloc] Income batch apply result: ${incomeResult.isRight()}");
    }

    // Handle the outcome
    if (batchFailure != null) {
      log.warning(
          "[TransactionListBloc] ApplyBatchCategory failed: ${batchFailure?.message}");
      emit(state.copyWith(
          status: ListStatus.error,
          errorMessage: _mapFailureToMessage(batchFailure!,
              context: "Failed batch category update")));
      // Keep batch mode active after error to allow user to see selection/retry/cancel
      emit(state.copyWith(status: ListStatus.success, clearErrorMessage: true));
    } else {
      log.info(
          "[TransactionListBloc] ApplyBatchCategory successful. Exiting batch mode and publishing events.");
      emit(state.copyWith(
          isInBatchEditMode: false,
          selectedTransactionIds: {},
          status: ListStatus.success,
          clearErrorMessage: true));
      // Publish events to trigger list refresh via _onDataChanged
      if (expenseIds.isNotEmpty)
        publishDataChangedEvent(
            type: DataChangeType.expense, reason: DataChangeReason.updated);
      if (incomeIds.isNotEmpty)
        publishDataChangedEvent(
            type: DataChangeType.income, reason: DataChangeReason.updated);
    }
  }

  Future<void> _onDeleteTransaction(
      DeleteTransaction event, Emitter<TransactionListState> emit) async {
    final txn = event.transaction;
    log.info(
        "[TransactionListBloc] DeleteTransaction requested: ID=${txn.id}, Type=${txn.type}");

    // Optimistic UI Update: Remove item from list and selection
    final optimisticList =
        state.transactions.where((t) => t.id != txn.id).toList();
    final updatedSelection = Set<String>.from(state.selectedTransactionIds)
      ..remove(txn.id);
    emit(state.copyWith(
        transactions: optimisticList,
        selectedTransactionIds: updatedSelection));

    // Call appropriate delete use case
    final deleteResult = txn.type == TransactionType.expense
        ? await _deleteExpenseUseCase(DeleteExpenseParams(txn.id))
        : await _deleteIncomeUseCase(DeleteIncomeParams(txn.id));

    // Handle result
    deleteResult.fold((failure) {
      log.warning(
          "[TransactionListBloc] DeleteTransaction failed for ${txn.id}: ${failure.message}");
      // Show error and revert UI by forcing a reload
      emit(state.copyWith(
          status: ListStatus.error,
          errorMessage:
              _mapFailureToMessage(failure, context: "Failed to delete")));
      add(const LoadTransactions(forceReload: true));
    }, (_) {
      log.info(
          "[TransactionListBloc] DeleteTransaction successful for ${txn.id}. DataChanged event will handle list update.");
      // Publish event (handled by _onDataChanged listener)
      publishDataChangedEvent(
          type: txn.type == TransactionType.expense
              ? DataChangeType.expense
              : DataChangeType.income,
          reason: DataChangeReason.deleted);
    });
  }

  Future<void> _onUserCategorizedTransaction(UserCategorizedTransaction event,
      Emitter<TransactionListState> emit) async {
    log.info(
        "[TransactionListBloc] UserCategorizedTransaction: ID=${event.transactionId}, Cat=${event.selectedCategory.name}");

    // 1. Save User History (Fire and forget, log errors)
    final historyParams = SaveUserCategorizationHistoryParams(
        transactionData: event.matchData,
        selectedCategory: event.selectedCategory);
    _saveUserHistoryUseCase(historyParams).then((result) {
      result.fold(
          (failure) => log.warning(
              "[TransactionListBloc] Failed to save user history: ${failure.message}"),
          (_) => log.info(
              "[TransactionListBloc] User history saved successfully for rule based on txn ${event.transactionId}"));
    }).catchError((e, s) {
      log.severe("[TransactionListBloc] Error saving user history");
    });

    // 2. Update the specific transaction's categorization state using the REPOSITORY
    log.info(
        "[TransactionListBloc] Updating categorization state for Txn ID: ${event.transactionId}");
    final repoResult = event.transactionType == TransactionType.expense
        ? await _expenseRepository.updateExpenseCategorization(
            event.transactionId,
            event.selectedCategory.id,
            CategorizationStatus.categorized,
            1.0) // Confidence 1.0 for manual set
        : await _incomeRepository.updateIncomeCategorization(
            event.transactionId,
            event.selectedCategory.id,
            CategorizationStatus.categorized,
            1.0);

    // Handle result of updating the transaction
    repoResult.fold((failure) {
      log.warning(
          "[TransactionListBloc] Failed to update categorization state for ${event.transactionId}: ${failure.message}");
      emit(state.copyWith(
          status: ListStatus.error,
          errorMessage: _mapFailureToMessage(failure,
              context: "Failed to update category")));
      // Optionally reload to revert optimistic UI if needed
      // add(const LoadTransactions(forceReload: true));
    }, (_) {
      log.info(
          "[TransactionListBloc] Categorization update successful for ${event.transactionId}. DataChanged event will refresh list.");
      // Publish event to trigger list reload via _onDataChanged
      publishDataChangedEvent(
          type: event.transactionType == TransactionType.expense
              ? DataChangeType.expense
              : DataChangeType.income,
          reason: DataChangeReason.updated);
    });
  }

  Future<void> _onDataChanged(
      _DataChanged event, Emitter<TransactionListState> emit) async {
    // Avoid triggering reload if already loading/reloading
    if (state.status != ListStatus.loading &&
        state.status != ListStatus.reloading) {
      log.info(
          "[TransactionListBloc] _DataChanged received. Triggering LoadTransactions.");
      add(const LoadTransactions(
          forceReload: true)); // Force reload to get latest data
    } else {
      log.info(
          "[TransactionListBloc] _DataChanged received, but already loading/reloading. Skipping explicit reload.");
    }
  }

  // Helper to map Failures to user-friendly strings
  String _mapFailureToMessage(Failure failure,
      {String context = "An error occurred"}) {
    log.warning(
        "[TransactionListBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
    switch (failure.runtimeType) {
      case CacheFailure:
        return '$context: Database Error: ${failure.message}';
      case ValidationFailure:
        return failure.message;
      default:
        return '$context: ${failure.message.isNotEmpty ? failure.message : 'An unknown error occurred.'}';
    }
  }

  // Cancel stream subscription on close
  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    log.info(
        "[TransactionListBloc] Closed and cancelled data stream subscription.");
    return super.close();
  }
}
