import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/get_incomes.dart';
import 'package:expense_tracker/features/categories/domain/usecases/apply_category_to_batch.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';

part 'income_list_event.dart';
part 'income_list_state.dart';

class IncomeListBloc extends Bloc<IncomeListEvent, IncomeListState> {
  final GetIncomesUseCase _getIncomesUseCase;
  final DeleteIncomeUseCase _deleteIncomeUseCase;
  final ApplyCategoryToBatchUseCase _applyCategoryToBatchUseCase;
  final SaveUserCategorizationHistoryUseCase _saveUserHistoryUseCase;
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  String? _currentCategory;
  String? _currentAccountId;

  IncomeListBloc({
    required GetIncomesUseCase getIncomesUseCase,
    required DeleteIncomeUseCase deleteIncomeUseCase,
    required ApplyCategoryToBatchUseCase applyCategoryToBatchUseCase,
    required SaveUserCategorizationHistoryUseCase saveUserHistoryUseCase,
    required Stream<DataChangedEvent> dataChangeStream,
  })  : _getIncomesUseCase = getIncomesUseCase,
        _deleteIncomeUseCase = deleteIncomeUseCase,
        _applyCategoryToBatchUseCase = applyCategoryToBatchUseCase,
        _saveUserHistoryUseCase = saveUserHistoryUseCase,
        super(const IncomeListInitial()) {
    on<LoadIncomes>(_onLoadIncomes);
    on<FilterIncomes>(_onFilterIncomes);
    on<DeleteIncomeRequested>(_onDeleteIncomeRequested);
    on<ToggleBatchEditMode>(_onToggleBatchEditMode);
    on<SelectIncome>(_onSelectIncome);
    on<ApplyBatchCategory>(_onApplyBatchCategory);
    on<UpdateSingleIncomeCategory>(_onUpdateSingleIncomeCategory);
    on<UserCategorizedIncome>(_onUserCategorizedIncome);
    on<_DataChanged>(_onDataChanged); // Ensure handler is registered

    _dataChangeSubscription = dataChangeStream.listen((event) {
      if (event.type == DataChangeType.income ||
          event.type == DataChangeType.category ||
          event.type == DataChangeType.settings) {
        log.info(
            "[IncomeListBloc] Received relevant DataChangedEvent: $event. Triggering reload.");
        add(const _DataChanged()); // Dispatch internal event
      }
    }, onError: (error, stackTrace) {
      log.severe("[IncomeListBloc] Error in dataChangeStream listener: $error");
    });
    log.info("[IncomeListBloc] Initialized and subscribed to data changes.");
  }

  // --- ADDED Missing Handler ---
  // Internal event handler to trigger reload
  Future<void> _onDataChanged(
      _DataChanged event, Emitter<IncomeListState> emit) async {
    // Only reload if the state is not already loading to avoid concurrent loads
    if (state is! IncomeListLoading) {
      log.info(
          "[IncomeListBloc] Handling _DataChanged event. Dispatching LoadIncomes(forceReload: true).");
      add(const LoadIncomes(forceReload: true));
    } else {
      log.info(
          "[IncomeListBloc] Handling _DataChanged event. State is already loading, skipping reload dispatch.");
    }
  }
  // --- END ADDED ---

  // ... (rest of the handlers: _onLoadIncomes, _onFilterIncomes, etc. remain as corrected before) ...
  Future<void> _onLoadIncomes(
      LoadIncomes event, Emitter<IncomeListState> emit) async {
    log.info(
        "[IncomeListBloc] Received LoadIncomes event (forceReload: ${event.forceReload}). Current state: ${state.runtimeType}");
    final currentState = state;
    final bool wasInBatchEdit =
        currentState is IncomeListLoaded && currentState.isInBatchEditMode;
    final Set<String> previousSelection = currentState is IncomeListLoaded
        ? currentState.selectedTransactionIds
        : {};

    if (currentState is! IncomeListLoaded || event.forceReload) {
      emit(IncomeListLoading(isReloading: currentState is IncomeListLoaded));
      log.info(
          "[IncomeListBloc] Emitting IncomeListLoading (isReloading: ${currentState is IncomeListLoaded}).");
    }

    final params = GetIncomesParams(
        startDate: _currentStartDate,
        endDate: _currentEndDate,
        category: _currentCategory,
        accountId: _currentAccountId);
    log.info(
        "[IncomeListBloc] Calling GetIncomesUseCase with params: AccID=${params.accountId}, Start=${params.startDate}, End=${params.endDate}, Cat=${params.category}");

    try {
      final result = await _getIncomesUseCase(params);
      log.info(
          "[IncomeListBloc] GetIncomesUseCase returned. isLeft: ${result.isLeft()}");

      result.fold(
        (failure) {
          log.warning(
              "[IncomeListBloc] Load failed: ${failure.message}. Emitting IncomeListError.");
          emit(IncomeListError(_mapFailureToMessage(failure)));
        },
        (incomes) {
          log.info(
              "[IncomeListBloc] Load successful. Emitting IncomeListLoaded with ${incomes.length} incomes. Preserving batch mode: $wasInBatchEdit");
          final validSelection = previousSelection
              .where((id) => incomes.any((inc) => inc.id == id))
              .toSet();
          emit(IncomeListLoaded(
            incomes: incomes,
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
      log.severe("[IncomeListBloc] Unexpected error in _onLoadIncomes");
      emit(IncomeListError(
          "An unexpected error occurred loading income: ${e.toString()}"));
    }
  }

  Future<void> _onFilterIncomes(
      FilterIncomes event, Emitter<IncomeListState> emit) async {
    log.info("[IncomeListBloc] Received FilterIncomes event.");
    if (state is IncomeListLoaded) {
      emit((state as IncomeListLoaded).copyWith(
        isInBatchEditMode: false,
        selectedTransactionIds: {},
      ));
    }
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _currentCategory = event.category;
    _currentAccountId = event.accountId;
    log.info(
        "[IncomeListBloc] Filters updated: AccID=$_currentAccountId, Start=$_currentStartDate, End=$_currentEndDate, Cat=$_currentCategory. Triggering load.");
    add(const LoadIncomes(forceReload: true));
  }

  Future<void> _onDeleteIncomeRequested(
      DeleteIncomeRequested event, Emitter<IncomeListState> emit) async {
    log.info(
        "[IncomeListBloc] Received DeleteIncomeRequested for ID: ${event.incomeId}");
    final currentState = state;
    if (currentState is IncomeListLoaded) {
      log.info(
          "[IncomeListBloc] Current state is Loaded. Performing optimistic delete.");
      final optimisticList =
          currentState.items.where((inc) => inc.id != event.incomeId).toList();
      final updatedSelection =
          Set<String>.from(currentState.selectedTransactionIds)
            ..remove(event.incomeId);
      log.info(
          "[IncomeListBloc] Optimistic list size: ${optimisticList.length}. Emitting updated IncomeListLoaded.");
      emit(currentState.copyWith(
          incomes: optimisticList, selectedTransactionIds: updatedSelection));

      try {
        final result =
            await _deleteIncomeUseCase(DeleteIncomeParams(event.incomeId));
        log.info(
            "[IncomeListBloc] DeleteIncomeUseCase returned. isLeft: ${result.isLeft()}");
        result.fold(
          (failure) {
            log.warning(
                "[IncomeListBloc] Deletion failed: ${failure.message}. Reverting UI and emitting Error.");
            emit(currentState);
            emit(IncomeListError(_mapFailureToMessage(failure,
                context: "Failed to delete income")));
          },
          (_) {
            log.info(
                "[IncomeListBloc] Deletion successful. Publishing DataChangedEvent.");
            publishDataChangedEvent(
                type: DataChangeType.income, reason: DataChangeReason.deleted);
          },
        );
      } catch (e, s) {
        log.severe(
            "[IncomeListBloc] Unexpected error in _onDeleteIncomeRequested for ID ${event.incomeId}");
        emit(currentState);
        emit(IncomeListError(
            "An unexpected error occurred during income deletion: ${e.toString()}"));
      }
    } else {
      log.warning(
          "[IncomeListBloc] Delete requested but state is not IncomeListLoaded. Ignoring.");
    }
  }

  void _onToggleBatchEditMode(
      ToggleBatchEditMode event, Emitter<IncomeListState> emit) {
    if (state is IncomeListLoaded) {
      final currentLoadedState = state as IncomeListLoaded;
      final newMode = !currentLoadedState.isInBatchEditMode;
      log.info("[IncomeListBloc] Toggling Batch Edit Mode to: $newMode");
      emit(currentLoadedState.copyWith(
        isInBatchEditMode: newMode,
        selectedTransactionIds:
            newMode ? currentLoadedState.selectedTransactionIds : {},
      ));
    } else {
      log.warning(
          "[IncomeListBloc] ToggleBatchEditMode ignored: State is not Loaded.");
    }
  }

  void _onSelectIncome(SelectIncome event, Emitter<IncomeListState> emit) {
    if (state is IncomeListLoaded) {
      final currentLoadedState = state as IncomeListLoaded;
      if (!currentLoadedState.isInBatchEditMode) {
        log.warning(
            "[IncomeListBloc] SelectIncome ignored: Not in Batch Edit Mode.");
        return;
      }
      final currentSelection = currentLoadedState.selectedTransactionIds;
      final newSelection = Set<String>.from(currentSelection);
      if (newSelection.contains(event.incomeId)) {
        newSelection.remove(event.incomeId);
        log.fine("[IncomeListBloc] Deselected income ID: ${event.incomeId}");
      } else {
        newSelection.add(event.incomeId);
        log.fine("[IncomeListBloc] Selected income ID: ${event.incomeId}");
      }
      emit(currentLoadedState.copyWith(selectedTransactionIds: newSelection));
    } else {
      log.warning(
          "[IncomeListBloc] SelectIncome ignored: State is not Loaded.");
    }
  }

  Future<void> _onApplyBatchCategory(
      ApplyBatchCategory event, Emitter<IncomeListState> emit) async {
    if (state is IncomeListLoaded) {
      final currentLoadedState = state as IncomeListLoaded;
      if (!currentLoadedState.isInBatchEditMode ||
          currentLoadedState.selectedTransactionIds.isEmpty) {
        log.warning(
            "[IncomeListBloc] ApplyBatchCategory ignored: Not in batch mode or no items selected.");
        return;
      }
      log.info(
          "[IncomeListBloc] Applying category '${event.categoryId}' to ${currentLoadedState.selectedTransactionIds.length} incomes.");

      final params = ApplyCategoryToBatchParams(
        transactionIds: currentLoadedState.selectedTransactionIds.toList(),
        categoryId: event.categoryId,
        transactionType: TransactionType.income,
      );
      final result = await _applyCategoryToBatchUseCase(params);

      result.fold((failure) {
        log.warning(
            "[IncomeListBloc] ApplyBatchCategory failed: ${failure.message}");
        emit(IncomeListError(_mapFailureToMessage(failure,
            context: "Failed to apply category to batch")));
        emit(currentLoadedState);
      }, (_) {
        log.info(
            "[IncomeListBloc] ApplyBatchCategory successful. Exiting batch mode and reloading.");
        emit(currentLoadedState
            .copyWith(isInBatchEditMode: false, selectedTransactionIds: {}));
        publishDataChangedEvent(
            type: DataChangeType.income, reason: DataChangeReason.updated);
      });
    } else {
      log.warning(
          "[IncomeListBloc] ApplyBatchCategory ignored: State is not Loaded.");
    }
  }

  Future<void> _onUpdateSingleIncomeCategory(
      UpdateSingleIncomeCategory event, Emitter<IncomeListState> emit) async {
    if (state is IncomeListLoaded) {
      final currentLoadedState = state as IncomeListLoaded;
      log.info(
          "[IncomeListBloc] Updating single income ${event.incomeId} to category ${event.categoryId}. Status: ${event.status.name}");

      final repo = sl<IncomeRepository>();
      final result = await repo.updateIncomeCategorization(
        event.incomeId,
        event.categoryId,
        event.status,
        event.confidence,
      );

      result.fold((failure) {
        log.warning(
            "[IncomeListBloc] UpdateSingleIncomeCategory failed: ${failure.message}");
        emit(IncomeListError(_mapFailureToMessage(failure,
            context: "Failed to update category")));
        emit(currentLoadedState);
      }, (_) {
        log.info(
            "[IncomeListBloc] UpdateSingleIncomeCategory successful in repo. DataChanged event will reload list.");
        publishDataChangedEvent(
            type: DataChangeType.income, reason: DataChangeReason.updated);
      });
    } else {
      log.warning(
          "[IncomeListBloc] UpdateSingleIncomeCategory ignored: State is not Loaded.");
    }
  }

  Future<void> _onUserCategorizedIncome(
      UserCategorizedIncome event, Emitter<IncomeListState> emit) async {
    if (state is! IncomeListLoaded) {
      log.warning(
          "[IncomeListBloc] UserCategorizedIncome ignored: State is not Loaded.");
      return;
    }
    log.info(
        "[IncomeListBloc] Handling UserCategorizedIncome for ID: ${event.incomeId}, Category: ${event.selectedCategory.name}");

    // 1. Save User History
    final historyParams = SaveUserCategorizationHistoryParams(
        transactionData: event.matchData,
        selectedCategory: event.selectedCategory);
    _saveUserHistoryUseCase(historyParams).then((result) {
      result.fold(
          (failure) => log.warning(
              "[IncomeListBloc] Failed to save user history: ${failure.message}"),
          (_) => log.info(
              "[IncomeListBloc] User history saved successfully for rule based on transaction ${event.incomeId}"));
    });

    // 2. Update the transaction status/category
    add(UpdateSingleIncomeCategory(
        incomeId: event.incomeId,
        categoryId: event.selectedCategory.id,
        status: CategorizationStatus.categorized,
        confidence: 1.0));
  }

  String _mapFailureToMessage(Failure failure,
      {String context = "An error occurred"}) {
    log.warning(
        "[IncomeListBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
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
    log.info("[IncomeListBloc] Canceled data change subscription and closing.");
    return super.close();
  }
}
