// lib/features/reports/presentation/bloc/income_expense_report/income_expense_report_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_income_expense_report.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/main.dart';

part 'income_expense_report_event.dart';
part 'income_expense_report_state.dart';

class IncomeExpenseReportBloc
    extends Bloc<IncomeExpenseReportEvent, IncomeExpenseReportState> {
  final GetIncomeExpenseReportUseCase _getReportUseCase;
  final ReportFilterBloc _reportFilterBloc;
  late final StreamSubscription _filterSubscription;

  IncomeExpenseReportBloc({
    required GetIncomeExpenseReportUseCase getIncomeExpenseReportUseCase,
    required ReportFilterBloc reportFilterBloc,
  }) : _getReportUseCase = getIncomeExpenseReportUseCase,
       _reportFilterBloc = reportFilterBloc,
       super(IncomeExpenseReportInitial()) {
    on<LoadIncomeExpenseReport>(_onLoadReport);
    on<ChangeIncomeExpensePeriod>(_onChangePeriod);
    on<_FilterChanged>(_onFilterChanged);

    _filterSubscription = _reportFilterBloc.stream.listen((filterState) {
      add(const _FilterChanged());
    });

    log.info("[IncomeExpenseReportBloc] Initialized.");
    add(
      const LoadIncomeExpenseReport(),
    ); // Initial load with default period & no comparison
  }

  void _onFilterChanged(
    _FilterChanged event,
    Emitter<IncomeExpenseReportState> emit,
  ) {
    log.info(
      "[IncomeExpenseReportBloc] Filter changed detected, reloading report.",
    );
    // Get current period and comparison state before reloading
    final currentPeriod = state is IncomeExpenseReportLoaded
        ? (state as IncomeExpenseReportLoaded).reportData.periodType
        : (state is IncomeExpenseReportLoading)
        ? (state as IncomeExpenseReportLoading).periodType
        : IncomeExpensePeriodType.monthly;
    final compare = state is IncomeExpenseReportLoaded
        ? (state as IncomeExpenseReportLoaded).showComparison
        : false;

    add(
      LoadIncomeExpenseReport(
        periodType: currentPeriod,
        compareToPrevious: compare,
      ),
    );
  }

  void _onChangePeriod(
    ChangeIncomeExpensePeriod event,
    Emitter<IncomeExpenseReportState> emit,
  ) {
    log.info(
      "[IncomeExpenseReportBloc] Period changed to ${event.periodType}. Reloading.",
    );
    // Get current comparison state before reloading
    final compare = state is IncomeExpenseReportLoaded
        ? (state as IncomeExpenseReportLoaded).showComparison
        : false;
    add(
      LoadIncomeExpenseReport(
        periodType: event.periodType,
        compareToPrevious: compare,
      ),
    );
  }

  Future<void> _onLoadReport(
    LoadIncomeExpenseReport event,
    Emitter<IncomeExpenseReportState> emit,
  ) async {
    final currentPeriodType =
        event.periodType ??
        (state is IncomeExpenseReportLoaded
            ? (state as IncomeExpenseReportLoaded).reportData.periodType
            : (state is IncomeExpenseReportLoading)
            ? (state as IncomeExpenseReportLoading).periodType
            : IncomeExpensePeriodType.monthly); // Default if not set

    // Use comparison flag from the event, default to false if not provided
    final bool compare = event.compareToPrevious;

    // Avoid duplicate loads for the exact same state (period AND comparison)
    if (state is IncomeExpenseReportLoading &&
        (state as IncomeExpenseReportLoading).periodType == currentPeriodType &&
        (state as IncomeExpenseReportLoading).compareToPrevious == compare) {
      log.fine(
        "[IncomeExpenseReportBloc] Already loading with same period type and comparison state.",
      );
      return;
    }

    emit(
      IncomeExpenseReportLoading(
        periodType: currentPeriodType,
        compareToPrevious: compare,
      ),
    ); // Pass compare flag
    log.info(
      "[IncomeExpenseReportBloc] Loading Income vs Expense report (Period: $currentPeriodType, Compare: $compare)...",
    );

    final filterState = _reportFilterBloc.state;
    final params = GetIncomeExpenseReportParams(
      startDate: filterState.startDate,
      endDate: filterState.endDate,
      periodType: currentPeriodType,
      accountIds: filterState.selectedAccountIds.isEmpty
          ? null
          : filterState.selectedAccountIds,
      compareToPrevious: compare, // Pass flag to use case
    );

    final result = await _getReportUseCase(params);

    result.fold(
      (failure) {
        log.warning(
          "[IncomeExpenseReportBloc] Load failed: ${failure.message}",
        );
        emit(IncomeExpenseReportError(_mapFailureToMessage(failure)));
      },
      (reportData) {
        log.info(
          "[IncomeExpenseReportBloc] Load successful. Period: ${reportData.periodType}, Points: ${reportData.periodData.length}, Comparison: $compare",
        );
        // Pass the comparison flag used for this load to the loaded state
        emit(IncomeExpenseReportLoaded(reportData, showComparison: compare));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    return failure.message;
  }

  @override
  Future<void> close() {
    _filterSubscription.cancel();
    log.info("[IncomeExpenseReportBloc] Closed and cancelled subscription.");
    return super.close();
  }
}
