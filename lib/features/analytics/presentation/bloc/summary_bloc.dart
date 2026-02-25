// lib/features/analytics/presentation/bloc/summary_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';

part 'summary_event.dart';
part 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  final GetExpenseSummaryUseCase _getExpenseSummaryUseCase;
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  // Keep track of current filters to re-apply on auto-refresh
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;

  SummaryBloc({
    required GetExpenseSummaryUseCase getExpenseSummaryUseCase,
    required Stream<DataChangedEvent> dataChangeStream,
  }) : _getExpenseSummaryUseCase = getExpenseSummaryUseCase,
       super(SummaryInitial()) {
    on<LoadSummary>(_onLoadSummary);
    on<_DataChanged>(_onDataChanged);
    on<ResetState>(_onResetState); // Add handler

    _dataChangeSubscription = dataChangeStream.listen(
      (event) {
        // --- MODIFIED Listener ---
        if (event.type == DataChangeType.system &&
            event.reason == DataChangeReason.reset) {
          log.info(
            "[SummaryBloc] System Reset event received. Adding ResetState.",
          );
          add(const ResetState());
        } else if (event.type == DataChangeType.expense ||
            event.type == DataChangeType.settings) {
          log.info(
            "[SummaryBloc] Relevant DataChangedEvent: $event. Triggering reload.",
          );
          add(const _DataChanged());
        }
        // --- END MODIFIED ---
      },
      onError: (error, stackTrace) {
        log.severe("[SummaryBloc] Error in dataChangeStream listener");
      },
    );
    log.info("[SummaryBloc] Initialized and subscribed to data changes.");
  }

  // --- ADDED: Reset State Handler ---
  void _onResetState(ResetState event, Emitter<SummaryState> emit) {
    log.info("[SummaryBloc] Resetting state to initial.");
    emit(SummaryInitial());
    add(const LoadSummary()); // Trigger initial load after reset
  }
  // --- END ADDED ---

  // ... (rest of handlers remain the same) ...
  Future<void> _onDataChanged(
    _DataChanged event,
    Emitter<SummaryState> emit,
  ) async {
    log.info(
      "[SummaryBloc] Handling _DataChanged event. Dispatching LoadSummary with current filters.",
    );
    // Reload summary using the last known filters, force reload
    add(
      LoadSummary(
        startDate: _currentStartDate,
        endDate: _currentEndDate,
        forceReload: true,
        updateFilters: false, // Don't update filters during auto-refresh
      ),
    );
  }

  Future<void> _onLoadSummary(
    LoadSummary event,
    Emitter<SummaryState> emit,
  ) async {
    log.info(
      "[SummaryBloc] Received LoadSummary event (forceReload: ${event.forceReload}, updateFilters: ${event.updateFilters}). Current state: ${state.runtimeType}",
    );

    // Update current filters only if explicitly requested
    if (event.updateFilters) {
      _currentStartDate = event.startDate;
      _currentEndDate = event.endDate;
      log.info(
        "[SummaryBloc] Filters updated from event: Start=$_currentStartDate, End=$_currentEndDate",
      );
    }

    // Emit loading state only if not already loaded or forced
    if (state is! SummaryLoaded || event.forceReload) {
      emit(SummaryLoading(isReloading: state is SummaryLoaded));
      log.info(
        "[SummaryBloc] Emitting SummaryLoading (isReloading: ${state is SummaryLoaded}).",
      );
    } else {
      log.info("[SummaryBloc] State is Loaded, refreshing data silently.");
    }

    // Use the stored (or newly updated) filters
    final params = GetSummaryParams(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
    );
    log.info(
      "[SummaryBloc] Calling GetExpenseSummaryUseCase with params: Start=${params.startDate}, End=${params.endDate}",
    );

    try {
      final result = await _getExpenseSummaryUseCase(params);
      log.info(
        "[SummaryBloc] GetExpenseSummaryUseCase returned. isLeft: ${result.isLeft()}",
      );

      result.fold(
        (failure) {
          log.warning(
            "[SummaryBloc] Load failed: ${failure.message}. Emitting SummaryError.",
          );
          emit(SummaryError(_mapFailureToMessage(failure)));
        },
        (summary) {
          log.info("[SummaryBloc] Load successful. Emitting SummaryLoaded.");
          emit(SummaryLoaded(summary));
        },
      );
    } catch (e, s) {
      log.severe("[SummaryBloc] Unexpected error in _onLoadSummary$e$s");
      emit(
        SummaryError(
          "An unexpected error occurred loading summary: ${e.toString()}",
        ),
      );
    }
  }

  String _mapFailureToMessage(Failure failure) {
    log.warning(
      "[SummaryBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}",
    );
    switch (failure.runtimeType) {
      case CacheFailure _:
        return 'Could not load summary from local data. ${failure.message}';
      case UnexpectedFailure _:
        return 'An unexpected error occurred loading the summary.';
      default:
        return failure.message.isNotEmpty
            ? failure.message
            : 'An unknown error occurred.';
    }
  }

  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    log.info("[SummaryBloc] Canceled data change subscription and closing.");
    return super.close();
  }
}
