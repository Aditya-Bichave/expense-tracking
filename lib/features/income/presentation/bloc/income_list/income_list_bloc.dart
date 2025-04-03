// lib/features/income/presentation/bloc/income_list/income_list_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/get_incomes.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl helper & publish
import 'package:expense_tracker/core/events/data_change_event.dart'; // Import event

// Import the specific states for this BLoC
part 'income_list_event.dart';
part 'income_list_state.dart';

class IncomeListBloc extends Bloc<IncomeListEvent, IncomeListState> {
  final GetIncomesUseCase _getIncomesUseCase;
  final DeleteIncomeUseCase _deleteIncomeUseCase;
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  // Store current filters
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  String? _currentCategory;
  String? _currentAccountId;

  IncomeListBloc({
    required GetIncomesUseCase getIncomesUseCase,
    required DeleteIncomeUseCase deleteIncomeUseCase,
    required Stream<DataChangedEvent> dataChangeStream,
  })  : _getIncomesUseCase = getIncomesUseCase,
        _deleteIncomeUseCase = deleteIncomeUseCase,
        super(const IncomeListInitial()) {
    // Use const constructor
    on<LoadIncomes>(_onLoadIncomes);
    on<FilterIncomes>(_onFilterIncomes);
    on<DeleteIncomeRequested>(_onDeleteIncomeRequested);
    on<_DataChanged>(_onDataChanged);

    _dataChangeSubscription = dataChangeStream.listen((event) {
      if (event.type == DataChangeType.income ||
          event.type == DataChangeType.settings) {
        log.info(
            "[IncomeListBloc] Received relevant DataChangedEvent: $event. Triggering reload.");
        add(const _DataChanged());
      }
    }, onError: (error, stackTrace) {
      log.severe(
          "[IncomeListBloc] Error in dataChangeStream listener"); // Pass error and stackTrace
    });
    log.info("[IncomeListBloc] Initialized and subscribed to data changes.");
  }

  // Internal event handler to trigger reload
  Future<void> _onDataChanged(
      _DataChanged event, Emitter<IncomeListState> emit) async {
    log.info(
        "[IncomeListBloc] Handling _DataChanged event. Dispatching LoadIncomes(forceReload: true).");
    add(const LoadIncomes(forceReload: true));
  }

  Future<void> _onLoadIncomes(
      LoadIncomes event, Emitter<IncomeListState> emit) async {
    log.info(
        "[IncomeListBloc] Received LoadIncomes event (forceReload: ${event.forceReload}). Current state: ${state.runtimeType}");

    // Emit Loading state using the correct class name
    if (state is! IncomeListLoaded || event.forceReload) {
      emit(IncomeListLoading(isReloading: state is IncomeListLoaded));
      log.info(
          "[IncomeListBloc] Emitting IncomeListLoading (isReloading: ${state is IncomeListLoaded}).");
    } else {
      log.info(
          "[IncomeListBloc] State is Loaded and no force reload. Refreshing data silently.");
    }

    final params = GetIncomesParams(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      category: _currentCategory,
      accountId: _currentAccountId,
    );
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
          // Emit Error state using the correct class name
          emit(IncomeListError(_mapFailureToMessage(failure)));
        },
        (incomes) {
          log.info(
              "[IncomeListBloc] Load successful. Emitting IncomeListLoaded with ${incomes.length} incomes.");
          // Emit Loaded state using the correct class name and parameters
          emit(IncomeListLoaded(
            incomes: incomes, // Pass the fetched incomes
            filterStartDate: _currentStartDate,
            filterEndDate: _currentEndDate,
            filterCategory: _currentCategory,
            filterAccountId: _currentAccountId,
          ));
        },
      );
    } catch (e, s) {
      // Capture stack trace
      log.severe("[IncomeListBloc] Unexpected error in _onLoadIncomes");
      // Emit Error state using the correct class name
      emit(IncomeListError(
          "An unexpected error occurred loading income: ${e.toString()}"));
    }
  }

  Future<void> _onFilterIncomes(
      FilterIncomes event, Emitter<IncomeListState> emit) async {
    log.info("[IncomeListBloc] Received FilterIncomes event.");
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _currentCategory = event.category;
    _currentAccountId = event.accountId;
    log.info(
        "[IncomeListBloc] Filters updated: AccID=$_currentAccountId, Start=$_currentStartDate, End=$_currentEndDate, Cat=$_currentCategory");
    add(const LoadIncomes(forceReload: true));
  }

  Future<void> _onDeleteIncomeRequested(
      DeleteIncomeRequested event, Emitter<IncomeListState> emit) async {
    log.info(
        "[IncomeListBloc] Received DeleteIncomeRequested for ID: ${event.incomeId}");
    final currentState = state;
    // Ensure state is IncomeListLoaded before optimistic update
    if (currentState is IncomeListLoaded) {
      log.info(
          "[IncomeListBloc] Current state is Loaded. Performing optimistic delete.");
      // Optimistic UI Update using 'items' from base state
      final optimisticList =
          currentState.items.where((inc) => inc.id != event.incomeId).toList();
      log.info(
          "[IncomeListBloc] Optimistic list size: ${optimisticList.length}. Emitting updated IncomeListLoaded.");
      // Emit updated state using the correct class name
      emit(IncomeListLoaded(
        incomes: optimisticList, // Pass as 'incomes'
        filterStartDate: currentState.filterStartDate,
        filterEndDate: currentState.filterEndDate,
        filterCategory: currentState.filterCategory,
        filterAccountId: currentState.filterAccountId,
      ));

      try {
        final result =
            await _deleteIncomeUseCase(DeleteIncomeParams(event.incomeId));
        log.info(
            "[IncomeListBloc] DeleteIncomeUseCase returned. isLeft: ${result.isLeft()}");

        result.fold(
          (failure) {
            log.warning(
                "[IncomeListBloc] Deletion failed: ${failure.message}. Reverting UI and emitting Error.");
            // Revert the optimistic update by emitting the original state
            emit(currentState);
            // Emit Error state using the correct class name
            emit(IncomeListError(_mapFailureToMessage(failure,
                context: "Failed to delete income")));
          },
          (_) {
            log.info(
                "[IncomeListBloc] Deletion successful. Publishing DataChangedEvent.");
            publishDataChangedEvent(
                type: DataChangeType.income, reason: DataChangeReason.deleted);
            // No state change needed here as UI was updated optimistically
          },
        );
      } catch (e, s) {
        // Capture stack trace
        log.severe(
            "[IncomeListBloc] Unexpected error in _onDeleteIncomeRequested for ID ${event.incomeId}");
        emit(currentState); // Revert optimistic update
        // Emit Error state using the correct class name
        emit(IncomeListError(
            "An unexpected error occurred during income deletion: ${e.toString()}"));
      }
    } else {
      log.warning(
          "[IncomeListBloc] Delete requested but state is not IncomeListLoaded. Ignoring.");
    }
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
