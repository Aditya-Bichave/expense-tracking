// lib/features/reports/presentation/bloc/spending_time_report/spending_time_report_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_time_report.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/main.dart';

part 'spending_time_report_event.dart';
part 'spending_time_report_state.dart';

class SpendingTimeReportBloc
    extends Bloc<SpendingTimeReportEvent, SpendingTimeReportState> {
  final GetSpendingTimeReportUseCase _getReportUseCase;
  final ReportFilterBloc _reportFilterBloc;
  late final StreamSubscription _filterSubscription;

  SpendingTimeReportBloc({
    required GetSpendingTimeReportUseCase getSpendingTimeReportUseCase,
    required ReportFilterBloc reportFilterBloc,
  }) : _getReportUseCase = getSpendingTimeReportUseCase,
       _reportFilterBloc = reportFilterBloc,
       super(SpendingTimeReportInitial()) {
    on<LoadSpendingTimeReport>(_onLoadReport);
    on<ChangeGranularity>(_onChangeGranularity);
    on<_FilterChanged>(_onFilterChanged); // Internal

    _filterSubscription = _reportFilterBloc.stream.listen((filterState) {
      add(const _FilterChanged());
    });

    log.info("[SpendingTimeReportBloc] Initialized.");
    add(
      const LoadSpendingTimeReport(),
    ); // Initial load with default granularity & no comparison
  }

  void _onFilterChanged(
    _FilterChanged event,
    Emitter<SpendingTimeReportState> emit,
  ) {
    log.info(
      "[SpendingTimeReportBloc] Filter changed detected, reloading report.",
    );
    // Get current granularity and comparison state before reloading
    final currentGranularity = state is SpendingTimeReportLoaded
        ? (state as SpendingTimeReportLoaded).reportData.granularity
        : (state is SpendingTimeReportLoading)
        ? (state as SpendingTimeReportLoading).granularity
        : TimeSeriesGranularity.daily;
    final compare = state is SpendingTimeReportLoaded
        ? (state as SpendingTimeReportLoaded).showComparison
        : false;

    add(
      LoadSpendingTimeReport(
        granularity: currentGranularity,
        compareToPrevious: compare,
      ),
    );
  }

  void _onChangeGranularity(
    ChangeGranularity event,
    Emitter<SpendingTimeReportState> emit,
  ) {
    log.info(
      "[SpendingTimeReportBloc] Granularity changed to ${event.granularity}. Reloading.",
    );
    // Get current comparison state before reloading
    final compare = state is SpendingTimeReportLoaded
        ? (state as SpendingTimeReportLoaded).showComparison
        : false;
    add(
      LoadSpendingTimeReport(
        granularity: event.granularity,
        compareToPrevious: compare,
      ),
    );
  }

  Future<void> _onLoadReport(
    LoadSpendingTimeReport event,
    Emitter<SpendingTimeReportState> emit,
  ) async {
    final currentGranularity =
        event.granularity ??
        (state is SpendingTimeReportLoaded
            ? (state as SpendingTimeReportLoaded).reportData.granularity
            : (state is SpendingTimeReportLoading)
            ? (state as SpendingTimeReportLoading).granularity
            : TimeSeriesGranularity.daily);

    final bool compare = event.compareToPrevious; // Use flag from event

    // Avoid duplicate loads for the exact same state (granularity AND comparison)
    if (state is SpendingTimeReportLoading &&
        (state as SpendingTimeReportLoading).granularity ==
            currentGranularity &&
        (state as SpendingTimeReportLoading).compareToPrevious == compare) {
      log.fine(
        "[SpendingTimeReportBloc] Already loading with same granularity and comparison state.",
      );
      return;
    }

    emit(
      SpendingTimeReportLoading(
        granularity: currentGranularity,
        compareToPrevious: compare,
      ),
    ); // Pass compare flag
    log.info(
      "[SpendingTimeReportBloc] Loading spending over time report (Granularity: $currentGranularity, Compare: $compare)...",
    );

    final filterState = _reportFilterBloc.state;
    final params = GetSpendingTimeReportParams(
      startDate: filterState.startDate,
      endDate: filterState.endDate,
      granularity: currentGranularity,
      accountIds: filterState.selectedAccountIds.isEmpty
          ? null
          : filterState.selectedAccountIds,
      categoryIds: filterState.selectedCategoryIds.isEmpty
          ? null
          : filterState.selectedCategoryIds,
      transactionType:
          filterState.selectedTransactionType, // Pass transaction type filter
      compareToPrevious: compare, // Pass flag to use case
    );

    final result = await _getReportUseCase(params);

    result.fold(
      (failure) {
        log.warning("[SpendingTimeReportBloc] Load failed: ${failure.message}");
        emit(SpendingTimeReportError(_mapFailureToMessage(failure)));
      },
      (reportData) {
        log.info(
          "[SpendingTimeReportBloc] Load successful. Granularity: ${reportData.granularity}, Points: ${reportData.spendingData.length}, Comparison: $compare",
        );
        // Pass the comparison flag used for this load to the loaded state
        emit(SpendingTimeReportLoaded(reportData, showComparison: compare));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    return failure.message;
  }

  @override
  Future<void> close() {
    _filterSubscription.cancel();
    log.info("[SpendingTimeReportBloc] Closed and cancelled subscription.");
    return super.close();
  }
}
