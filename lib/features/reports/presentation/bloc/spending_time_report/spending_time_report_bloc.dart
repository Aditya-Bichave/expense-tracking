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
  })  : _getReportUseCase = getSpendingTimeReportUseCase,
        _reportFilterBloc = reportFilterBloc,
        super(SpendingTimeReportInitial()) {
    on<LoadSpendingTimeReport>(_onLoadReport);
    on<ChangeGranularity>(_onChangeGranularity);
    on<_FilterChanged>(_onFilterChanged); // Internal

    _filterSubscription = _reportFilterBloc.stream.listen((filterState) {
      add(const _FilterChanged());
    });

    log.info("[SpendingTimeReportBloc] Initialized.");
    add(const LoadSpendingTimeReport()); // Initial load
  }

  void _onFilterChanged(
      _FilterChanged event, Emitter<SpendingTimeReportState> emit) {
    log.info(
        "[SpendingTimeReportBloc] Filter changed detected, reloading report.");
    add(LoadSpendingTimeReport(
        granularity: state is SpendingTimeReportLoaded
            ? (state as SpendingTimeReportLoaded).reportData.granularity
            : TimeSeriesGranularity.daily // Default if not loaded yet
        ));
  }

  void _onChangeGranularity(
      ChangeGranularity event, Emitter<SpendingTimeReportState> emit) {
    log.info(
        "[SpendingTimeReportBloc] Granularity changed to ${event.granularity}. Reloading.");
    add(LoadSpendingTimeReport(granularity: event.granularity));
  }

  Future<void> _onLoadReport(LoadSpendingTimeReport event,
      Emitter<SpendingTimeReportState> emit) async {
    // Use granularity from event, or current state, or default
    final currentGranularity = event.granularity ??
        (state is SpendingTimeReportLoaded
            ? (state as SpendingTimeReportLoaded).reportData.granularity
            : TimeSeriesGranularity.daily);

    if (state is SpendingTimeReportLoading &&
        (state as SpendingTimeReportLoading).granularity ==
            currentGranularity) {
      log.fine(
          "[SpendingTimeReportBloc] Already loading with same granularity.");
      return; // Avoid concurrent loads for the same granularity
    }

    emit(SpendingTimeReportLoading(granularity: currentGranularity));
    log.info(
        "[SpendingTimeReportBloc] Loading spending over time report (Granularity: $currentGranularity)...");

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
    );

    final result = await _getReportUseCase(params);

    result.fold(
      (failure) {
        log.warning("[SpendingTimeReportBloc] Load failed: ${failure.message}");
        emit(SpendingTimeReportError(_mapFailureToMessage(failure)));
      },
      (reportData) {
        log.info(
            "[SpendingTimeReportBloc] Load successful. Granularity: ${reportData.granularity}, Points: ${reportData.spendingData.length}");
        emit(SpendingTimeReportLoaded(reportData));
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
