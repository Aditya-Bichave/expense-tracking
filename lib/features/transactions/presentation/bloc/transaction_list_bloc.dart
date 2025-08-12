// lib/features/transactions/presentation/bloc/transaction_list_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz/dartz.dart'; // Add this if missing for Either
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
// CategorizationStatus
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
import 'package:flutter/material.dart';

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
    on<LoadTransactions>(_onLoadTransactions, transformer: restartable());
    on<FilterChanged>(_onFilterChanged);
    on<SortChanged>(_onSortChanged);
    on<SearchChanged>(_onSearchChanged);
    on<ToggleBatchEdit>(_onToggleBatchEdit);
    on<SelectTransaction>(_onSelectTransaction);
    on<ApplyBatchCategory>(_onApplyBatchCategory);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<UserCategorizedTransaction>(_onUserCategorizedTransaction);
    on<ResetState>(_onResetState); // Add Reset Handler

    // Subscribe to Data Change Stream
    _dataChangeSubscription = dataChangeStream.listen((event) {
      if (event.type == DataChangeType.system &&
          event.reason == DataChangeReason.reset) {
        log.info(
            "[TransactionListBloc] System Reset event received. Adding ResetState.");
        add(const ResetState()); // Dispatch ResetState internally
      } else if (event.type == DataChangeType.expense ||
          event.type == DataChangeType.income ||
          event.type == DataChangeType.category ||
          event.type == DataChangeType.account ||
          event.type == DataChangeType.settings) {
        log.info(
            "[TransactionListBloc] Relevant DataChangedEvent: $event. Triggering reload.");
        add(const LoadTransactions(forceReload: true));
      }
    }, onError: (error, stackTrace) {
      log.severe(
          "[TransactionListBloc] Error in dataChangeStream listener: $error");
    });
    log.info(
        "[TransactionListBloc] Initialized and subscribed to data changes.");
  }

  // --- Add Reset State Handler ---
  void _onResetState(ResetState event, Emitter<TransactionListState> emit) {
    log.info("[TransactionListBloc] Resetting state to initial.");
    emit(const TransactionListState()); // Emit the initial state
    // Optionally, trigger an initial load after resetting
    // add(const LoadTransactions());
  }
  // --- End Reset Handler ---

  // --- Event Handlers (Rest remain the same) ---
  Future<void> _onLoadTransactions(
      LoadTransactions event, Emitter<TransactionListState> emit) async {
    log.info(
        "[TransactionListBloc] LoadTransactions triggered. ForceReload: ${event.forceReload}, Incoming Filters: ${event.incomingFilters}");

    // Determine current filters from state, potentially overridden by incoming filters
    DateTime? startDate = event.incomingFilters?['startDate'] != null
        ? DateTime.tryParse(event.incomingFilters!['startDate'] as String)
        : state.startDate;
    DateTime? endDate = event.incomingFilters?['endDate'] != null
        ? DateTime.tryP...

  Future<void> _onFilterChanged(
      FilterChanged event, Emitter<TransactionListState> emit) async {
    log.info("[TransactionListBloc] FilterChanged triggered.");
    // Update state first (sets filters, clears batch mode)
    emit(state.copyWith(
      startDate: event.startDate,
      endDate: event.endDate,
      categoryId: event.categoryId,
      accountId: event.accountId,
      transactionType: event.transactionType,
      isInBatchEditMode: false,
      selectedTransactionIds: {},
      clearStartDate: event.startDate == null && state.startDate != null,
      clearEndDate: event.endDate == null && state.endDate != null,
      clearCategoryId: event.categoryId == null && state.categoryId != null,
      clearAccountId: event.accountId == null && state.accountId != null,
      clearTransactionType:
          event.transactionType == null && state.transactionType != null,
      clearErrorMessage: true,
    ));
    // Then trigger LoadTransactions which will use the new state filters
    add(const LoadTransactions(forceReload: true));
  }

  Future<void> _onSortChanged(
      SortChanged event, Emitter<TransactionListState> emit) async {
    log.info(
        "[TransactionListBloc] SortChanged triggered: ${event.sortBy}.${event.sortDirection}");
    // Update state first
    emit(state.copyWith(
      sortBy: event.sortBy,
      sortDirection: event.sortDirection,
      isInBatchEditMode: false,
      selectedTransactionIds: {},
      clearErrorMessage: true,
    ));
    // Then trigger reload
    add(const LoadTransactions(forceReload: true));
  }

  Future<void> _onSearchChanged(
      SearchChanged event, Emitter<TransactionListState> emit) async {
    log.info(
        "[TransactionListBloc] SearchChanged triggered: '${event.searchTerm}'");
    // Update state first
    emit(state.copyWith(
      searchTerm: event.searchTerm,
      clearSearchTerm: event.searchTerm == null || event.searchTerm!.isEmpty,
      isInBatchEditMode: false,
      selectedTransactionIds: {},
      clearErrorMessage: true,
    ));
    // Then trigger reload
    add(const LoadTransactions(forceReload: true));
  }

  void _onToggleBatchEdit(
      ToggleBatchEdit event, Emitter<TransactionListState> emit) {
    log.info("[TransactionListBloc] ToggleBatchEdit triggered.");
    final newMode = !state.isInBatchEditMode;
    emit(state.copyWith(
      isInBatchEditMode: newMode,
      selectedTransactionIds: newMode ? state.selectedTransactionIds : {},
      clearErrorMessage: true,
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
    final currentTransactions = state.transactions;

    for (final id in state.selectedTransactionIds) {
      final txn = currentTransactions.firstWhere((t) => t.id == id, orElse: () {
        log.severe(
            "[TransactionListBloc] CRITICAL: Selected ID $id not found in current transaction state during batch apply!");
        throw Exception(
            "Selected ID $id not found in state during batch apply");
      });
      if (txn.type == TransactionType.expense) {
        expenseIds.add(id);
      } else if (txn.type == TransactionType.income) {
        incomeIds.add(id);
      }
    }

    Failure? batchFailure;

    if (expenseIds.isNotEmpty) {
      final expenseParams = ApplyCategoryToBatchParams(
        transactionIds: expenseIds,
        categoryId: event.categoryId,
        transactionType: TransactionType.expense,
      );
      final expenseResult = await _applyCategoryToBatchUseCase(expenseParams);
      expenseResult.fold((f) => batchFailure = f, (_) {});
      log.fine(
          "[TransactionListBloc] Expense batch apply result: ${expenseResult.isRight()}");
    }

    if (batchFailure == null && incomeIds.isNotEmpty) {
      final incomeParams = ApplyCategoryToBatchParams(
        transactionIds: incomeIds,
        categoryId: event.categoryId,
        transactionType: TransactionType.income,
      );
      final incomeResult = await _applyCategoryToBatchUseCase(incomeParams);
      incomeResult.fold((f) => batchFailure = f, (_) {});
      log.fine(
          "[TransactionListBloc] Income batch apply result: ${incomeResult.isRight()}");
    }

    if (batchFailure != null) {
      log.warning(
          "[TransactionListBloc] ApplyBatchCategory failed: ${batchFailure?.message}");
      emit(state.copyWith(
          status: ListStatus.error,
          errorMessage: _mapFailureToMessage(batchFailure!,
              context: "Failed batch category update")));
      // Keep batch mode active, but reset status after showing error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state.status == ListStatus.error) {
          emit(state.copyWith(
              status: ListStatus.success, clearErrorMessage: true));
        }
      });
    } else {
      log.info(
          "[TransactionListBloc] ApplyBatchCategory successful. Exiting batch mode and publishing events.");
      emit(state.copyWith(
          isInBatchEditMode: false,
          selectedTransactionIds: {},
          status: ListStatus.success, // Important: Set back to success
          clearErrorMessage: true));
      // Events will trigger reload via _onDataChanged
      if (expenseIds.isNotEmpty) {
        publishDataChangedEvent(
            type: DataChangeType.expense, reason: DataChangeReason.updated);
      }
      if (incomeIds.isNotEmpty) {
        publishDataChangedEvent(
            type: DataChangeType.income, reason: DataChangeReason.updated);
      }
    }
  }

  Future<void> _onDeleteTransaction(
      DeleteTransaction event, Emitter<TransactionListState> emit) async {
    final txn = event.transaction;
    log.info(
        "[TransactionListBloc] DeleteTransaction requested: ID=${txn.id}, Type=${txn.type}");

    final optimisticList =
        state.transactions.where((t) => t.id != txn.id).toList();
    final updatedSelection = Set<String>.from(state.selectedTransactionIds)
      ..remove(txn.id);
    emit(state.copyWith(
        transactions: optimisticList,
        selectedTransactionIds: updatedSelection));

    final deleteResult = txn.type == TransactionType.expense
        ? await _deleteExpenseUseCase(DeleteExpenseParams(txn.id))
        : await _deleteIncomeUseCase(DeleteIncomeParams(txn.id));

    deleteResult.fold((failure) {
      log.warning(
          "[TransactionListBloc] DeleteTransaction failed for ${txn.id}: ${failure.message}");
      emit(state.copyWith(
          status: ListStatus.error,
          errorMessage:
              _mapFailureToMessage(failure, context: "Failed to delete")));
      // Trigger reload to revert optimistic delete and show error
      add(const LoadTransactions(forceReload: true));
    }, (_) {
      log.info(
          "[TransactionListBloc] DeleteTransaction successful for ${txn.id}. DataChanged event will handle list update.");
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

    // Save History (Fire and forget)
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
      log.severe("[TransactionListBloc] Error saving user history: $e\n$s");
    });

    // Update Transaction Categorization State
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
            1.0); // Confidence 1.0 for manual set

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
