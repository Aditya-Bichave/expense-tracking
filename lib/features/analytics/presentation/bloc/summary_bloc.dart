import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/main.dart'; // Import logger
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
  })  : _getExpenseSummaryUseCase = getExpenseSummaryUseCase,
        super(SummaryInitial()) {
    on<LoadSummary>(_onLoadSummary);
    on<_DataChanged>(_onDataChanged);

    _dataChangeSubscription = dataChangeStream.listen((event) {
      // Summary needs refresh if Expenses or Settings (currency) change
      if (event.type == DataChangeType.expense ||
          event.type == DataChangeType.settings) {
        log.info(
            "[SummaryBloc] Received relevant DataChangedEvent: $event. Triggering reload.");
        add(const _DataChanged());
      }
    }, onError: (error, stackTrace) {
      log.severe("[SummaryBloc] Error in dataChangeStream listener");
    });
    log.info("[SummaryBloc] Initialized and subscribed to data changes.");
  }

  // Internal event handler to trigger reload
  Future<void> _onDataChanged(
      _DataChanged event, Emitter<SummaryState> emit) async {
    log.info(
        "[SummaryBloc] Handling _DataChanged event. Dispatching LoadSummary with current filters.");
    // Reload summary using the last known filters, force reload
    add(LoadSummary(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      forceReload: true,
    ));
  }

  Future<void> _onLoadSummary(
      LoadSummary event, Emitter<SummaryState> emit) async {
    log.info(
        "[SummaryBloc] Received LoadSummary event (forceReload: ${event.forceReload}). Current state: ${state.runtimeType}");

    // Update current filters only if they are explicitly passed in this event
    // (avoids resetting filters during auto-refresh)
    if (event.updateFilters) {
      _currentStartDate = event.startDate;
      _currentEndDate = event.endDate;
      log.info(
          "[SummaryBloc] Filters updated from event: Start=$_currentStartDate, End=$_currentEndDate");
    }

    // Emit loading state only if not already loaded or forced
    if (state is! SummaryLoaded || event.forceReload) {
      emit(SummaryLoading(isReloading: state is SummaryLoaded));
      log.info(
          "[SummaryBloc] Emitting SummaryLoading (isReloading: ${state is SummaryLoaded}).");
    } else {
      log.info("[SummaryBloc] State is Loaded, refreshing data silently.");
    }

    // Use the stored (or newly updated) filters
    final params = GetSummaryParams(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
    );
    log.info(
        "[SummaryBloc] Calling GetExpenseSummaryUseCase with params: Start=${params.startDate}, End=${params.endDate}");

    try {
      final result = await _getExpenseSummaryUseCase(params);
      log.info(
          "[SummaryBloc] GetExpenseSummaryUseCase returned. isLeft: ${result.isLeft()}");

      result.fold(
        (failure) {
          log.warning(
              "[SummaryBloc] Load failed: ${failure.message}. Emitting SummaryError.");
          emit(SummaryError(_mapFailureToMessage(failure)));
        },
        (summary) {
          log.info("[SummaryBloc] Load successful. Emitting SummaryLoaded.");
          emit(SummaryLoaded(summary));
        },
      );
    } catch (e, s) {
      log.severe("[SummaryBloc] Unexpected error in _onLoadSummary$e$s");
      emit(SummaryError(
          "An unexpected error occurred loading summary: ${e.toString()}"));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    log.warning(
        "[SummaryBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'Could not load summary from local data. ${failure.message}';
      case UnexpectedFailure:
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
