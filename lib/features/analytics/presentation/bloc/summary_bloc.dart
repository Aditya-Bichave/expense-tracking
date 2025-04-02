import 'dart:async'; // Import async
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:expense_tracker/core/error/failure.dart'; // Import Failure type
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart'; // Import the use case
import 'package:expense_tracker/core/events/data_change_event.dart'; // Import event

// Link the state and event files
part 'summary_event.dart';
part 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  final GetExpenseSummaryUseCase _getExpenseSummaryUseCase; // Dependency
  late final StreamSubscription<DataChangedEvent>
      _dataChangeSubscription; // Subscription

  // Keep track of current filters to re-apply on auto-refresh
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;

  SummaryBloc({
    required GetExpenseSummaryUseCase getExpenseSummaryUseCase,
    required Stream<DataChangedEvent> dataChangeStream, // Inject stream
  })  : _getExpenseSummaryUseCase = getExpenseSummaryUseCase,
        super(SummaryInitial()) {
    on<LoadSummary>(_onLoadSummary);
    on<_DataChanged>(_onDataChanged); // Handler for internal event

    // *** Subscribe to the stream ***
    _dataChangeSubscription = dataChangeStream.listen((event) {
      // Summary only needs refresh if Expenses change
      if (event.type == DataChangeType.expense) {
        debugPrint(
            "[SummaryBloc] Received relevant DataChangedEvent: $event. Adding _DataChanged event.");
        add(const _DataChanged());
      }
    });
    debugPrint("[SummaryBloc] Initialized and subscribed to data changes.");
  }

  // Internal event handler to trigger reload
  Future<void> _onDataChanged(
      _DataChanged event, Emitter<SummaryState> emit) async {
    debugPrint(
        "[SummaryBloc] Handling _DataChanged event. Dispatching LoadSummary.");
    // Reload summary using the last known filters
    add(LoadSummary(
        startDate: _currentStartDate,
        endDate: _currentEndDate,
        forceReload: true));
  }

  // Handler function for the LoadSummary event
  Future<void> _onLoadSummary(
      LoadSummary event, Emitter<SummaryState> emit) async {
    debugPrint("[SummaryBloc] Received LoadSummary event.");

    // Update current filters
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;

    // Emit loading state (consider if flicker is an issue on auto-refresh)
    if (state is! SummaryLoaded || event.forceReload) {
      if (state is! SummaryLoaded) {
        debugPrint(
            "[SummaryBloc] Current state is not Loaded. Emitting SummaryLoading.");
        emit(SummaryLoading());
      } else {
        debugPrint("[SummaryBloc] Force reload requested. Refreshing data.");
      }
    } else {
      debugPrint(
          "[SummaryBloc] State is Loaded, refreshing without Loading state.");
    }

    // Create parameters for the use case from the event data
    final params = GetSummaryParams(
      startDate: event.startDate,
      endDate: event.endDate,
    );
    debugPrint(
        "[SummaryBloc] Calling GetExpenseSummaryUseCase with params: Start=${params.startDate}, End=${params.endDate}");

    try {
      final result = await _getExpenseSummaryUseCase(params);
      debugPrint(
          "[SummaryBloc] GetExpenseSummaryUseCase returned. Result isLeft: ${result.isLeft()}");

      result.fold(
        // If Left (Failure)
        (failure) {
          debugPrint("[SummaryBloc] Emitting SummaryError: ${failure.message}");
          emit(SummaryError(_mapFailureToMessage(failure)));
        },
        // If Right (Success)
        (summary) {
          debugPrint("[SummaryBloc] Emitting SummaryLoaded.");
          emit(SummaryLoaded(summary));
        },
      );
    } catch (e, s) {
      debugPrint("[SummaryBloc] *** CRITICAL ERROR in _onLoadSummary: $e\n$s");
      emit(SummaryError("An unexpected error occurred loading summary: $e"));
    } finally {
      debugPrint("[SummaryBloc] Finished processing LoadSummary.");
    }
  }

  // Helper function to convert Failure objects to user-friendly strings
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'Could not load summary from local data. ${failure.message}';
      // Add other failure types if needed (e.g., ServerFailure for cloud sync)
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }

  // *** Cancel subscription when BLoC is closed ***
  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    debugPrint("[SummaryBloc] Canceled data change subscription.");
    return super.close();
  }
}
