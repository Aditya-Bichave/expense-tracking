import 'dart:async'; // Import async
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/get_incomes.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl helper
import 'package:expense_tracker/core/events/data_change_event.dart'; // Import event

part 'income_list_event.dart';
part 'income_list_state.dart';

class IncomeListBloc extends Bloc<IncomeListEvent, IncomeListState> {
  final GetIncomesUseCase _getIncomesUseCase;
  final DeleteIncomeUseCase _deleteIncomeUseCase;
  late final StreamSubscription<DataChangedEvent>
      _dataChangeSubscription; // Subscription

  // Store current filters to re-apply on refresh/filtering
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  String? _currentCategory;
  String?
      _currentAccountId; // Account filter applied in repo, store if needed for UI state

  IncomeListBloc({
    required GetIncomesUseCase getIncomesUseCase,
    required DeleteIncomeUseCase deleteIncomeUseCase,
    required Stream<DataChangedEvent> dataChangeStream, // Inject stream
  })  : _getIncomesUseCase = getIncomesUseCase,
        _deleteIncomeUseCase = deleteIncomeUseCase,
        super(IncomeListInitial()) {
    on<LoadIncomes>(_onLoadIncomes);
    on<FilterIncomes>(_onFilterIncomes);
    on<DeleteIncomeRequested>(_onDeleteIncomeRequested);
    on<_DataChanged>(_onDataChanged); // Handler for internal event

    // Subscribe to the data change stream
    _dataChangeSubscription = dataChangeStream.listen((event) {
      // Income list needs refresh if Income changes directly
      if (event.type == DataChangeType.income) {
        debugPrint(
            "[IncomeListBloc] Received relevant DataChangedEvent: $event. Adding _DataChanged event.");
        add(const _DataChanged());
      }
    });

    debugPrint("[IncomeListBloc] Initialized and subscribed to data changes.");
  }

  // Internal event handler to trigger reload
  Future<void> _onDataChanged(
      _DataChanged event, Emitter<IncomeListState> emit) async {
    debugPrint(
        "[IncomeListBloc] Handling _DataChanged event. Dispatching LoadIncomes.");
    // Trigger reload, force update to reflect changes immediately
    add(const LoadIncomes(forceReload: true));
  }

  // Handler for loading incomes
  Future<void> _onLoadIncomes(
      LoadIncomes event, Emitter<IncomeListState> emit) async {
    debugPrint(
        "[IncomeListBloc] Received LoadIncomes event. ForceReload: ${event.forceReload}");
    // Show loading only if not already loaded or if forced
    if (state is! IncomeListLoaded || event.forceReload) {
      if (state is! IncomeListLoaded) {
        debugPrint(
            "[IncomeListBloc] Current state is not Loaded. Emitting IncomeListLoading.");
        emit(IncomeListLoading());
      } else {
        debugPrint("[IncomeListBloc] Force reload requested. Refreshing data.");
      }
    } else {
      debugPrint(
          "[IncomeListBloc] Current state is Loaded and no force reload. Refreshing data without emitting Loading.");
    }

    // Use stored filters for loading
    final params = GetIncomesParams(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      category: _currentCategory,
      accountId: _currentAccountId, // Pass account ID if stored/needed
    );
    debugPrint(
        "[IncomeListBloc] Calling GetIncomesUseCase with params: AccID=${params.accountId}, Start=${params.startDate}, End=${params.endDate}, Cat=${params.category}");

    try {
      final result = await _getIncomesUseCase(params);
      debugPrint(
          "[IncomeListBloc] GetIncomesUseCase returned. Result isLeft: ${result.isLeft()}");

      result.fold(
        // On Failure
        (failure) {
          debugPrint(
              "[IncomeListBloc] Emitting IncomeListError: ${failure.message}");
          emit(IncomeListError(_mapFailureToMessage(failure)));
        },
        // On Success
        (incomes) {
          debugPrint(
              "[IncomeListBloc] Emitting IncomeListLoaded with ${incomes.length} incomes.");
          emit(IncomeListLoaded(
            incomes: incomes,
            filterStartDate: _currentStartDate,
            filterEndDate: _currentEndDate,
            filterCategory: _currentCategory,
            filterAccountId: _currentAccountId,
          ));
        },
      );
    } catch (e, s) {
      debugPrint(
          "[IncomeListBloc] *** CRITICAL ERROR in _onLoadIncomes: $e\n$s");
      emit(IncomeListError(
          "An unexpected error occurred in the Income BLoC: $e"));
    } finally {
      debugPrint(
          "[IncomeListBloc] Finished processing LoadIncomes event handler.");
    }
  }

  // Handler for applying filters
  Future<void> _onFilterIncomes(
      FilterIncomes event, Emitter<IncomeListState> emit) async {
    debugPrint("[IncomeListBloc] Received FilterIncomes event.");
    emit(IncomeListLoading()); // Show loading when filters change

    // Update stored filters
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _currentCategory = event.category;
    _currentAccountId = event.accountId;
    debugPrint(
        "[IncomeListBloc] Filters updated: AccID=$_currentAccountId, Start=$_currentStartDate, End=$_currentEndDate, Cat=$_currentCategory");

    // Trigger load with new filters
    add(const LoadIncomes());
  }

  // Handler for deleting income
  Future<void> _onDeleteIncomeRequested(
      DeleteIncomeRequested event, Emitter<IncomeListState> emit) async {
    debugPrint(
        "[IncomeListBloc] Received DeleteIncomeRequested for ID: ${event.incomeId}");
    final currentState = state;
    if (currentState is IncomeListLoaded) {
      debugPrint(
          "[IncomeListBloc] Current state is Loaded. Proceeding with optimistic delete.");
      // Optimistic UI Update
      final optimisticList = currentState.incomes
          .where((inc) => inc.id != event.incomeId)
          .toList();
      debugPrint(
          "[IncomeListBloc] Optimistic list size: ${optimisticList.length}. Emitting updated IncomeListLoaded.");
      emit(IncomeListLoaded(
        incomes: optimisticList,
        filterStartDate: currentState.filterStartDate,
        filterEndDate: currentState.filterEndDate,
        filterCategory: currentState.filterCategory,
        filterAccountId: currentState.filterAccountId,
      ));

      try {
        final result =
            await _deleteIncomeUseCase(DeleteIncomeParams(event.incomeId));
        debugPrint(
            "[IncomeListBloc] DeleteIncomeUseCase returned. Result isLeft: ${result.isLeft()}");

        result.fold(
          // On Failure
          (failure) {
            debugPrint(
                "[IncomeListBloc] Deletion failed: ${failure.message}. Reverting UI and emitting Error.");
            // Revert UI and show error
            emit(currentState);
            emit(IncomeListError(// Separate error state
                "Failed to delete income: ${_mapFailureToMessage(failure)}"));
            // Optionally trigger reload: add(LoadIncomes(forceReload: true));
          },
          // On Success
          (_) {
            debugPrint(
                "[IncomeListBloc] Deletion successful (Optimistic UI). Publishing DataChangedEvent.");
            // Publish event so other Blocs (Dashboard, Accounts) can react
            publishDataChangedEvent(
                type: DataChangeType.income, reason: DataChangeReason.deleted);
          },
        );
      } catch (e, s) {
        debugPrint(
            "[IncomeListBloc] *** CRITICAL ERROR in _onDeleteIncomeRequested: $e\n$s");
        // Revert optimistic update on error
        emit(currentState);
        emit(IncomeListError(
            "An unexpected error occurred during income deletion: $e"));
      }
    } else {
      debugPrint(
          "[IncomeListBloc] Delete requested but state is not IncomeListLoaded. Ignoring.");
    }
    debugPrint("[IncomeListBloc] Finished processing DeleteIncomeRequested.");
  }

  // Helper to map Failures to messages
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'Database Error: ${failure.message}';
      case ValidationFailure:
        return failure.message;
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }

  // Cancel stream subscription when BLoC is closed
  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    debugPrint("[IncomeListBloc] Canceled data change subscription.");
    return super.close();
  }
}
