// lib/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_budget_performance_report.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/main.dart';

part 'budget_performance_report_event.dart';
part 'budget_performance_report_state.dart';

class BudgetPerformanceReportBloc
    extends Bloc<BudgetPerformanceReportEvent, BudgetPerformanceReportState> {
  final GetBudgetPerformanceReportUseCase _getReportUseCase;
  final ReportFilterBloc _reportFilterBloc;
  late final StreamSubscription _filterSubscription;

  BudgetPerformanceReportBloc({
    required GetBudgetPerformanceReportUseCase
        getBudgetPerformanceReportUseCase,
    required ReportFilterBloc reportFilterBloc,
  })  : _getReportUseCase = getBudgetPerformanceReportUseCase,
        _reportFilterBloc = reportFilterBloc,
        super(BudgetPerformanceReportInitial()) {
    on<LoadBudgetPerformanceReport>(_onLoadReport);
    on<ToggleBudgetComparison>(_onToggleComparison);
    on<_FilterChanged>(_onFilterChanged);

    _filterSubscription = _reportFilterBloc.stream.listen((filterState) {
      add(const _FilterChanged());
    });

    log.info("[BudgetPerformanceReportBloc] Initialized.");
    add(const LoadBudgetPerformanceReport()); // Initial load
  }

  void _onFilterChanged(
      _FilterChanged event, Emitter<BudgetPerformanceReportState> emit) {
    log.info(
        "[BudgetPerformanceReportBloc] Filter changed detected, reloading report.");
    // Reload with current comparison setting
    final bool compare = state is BudgetPerformanceReportLoaded
        ? (state as BudgetPerformanceReportLoaded).showComparison
        : false;
    add(LoadBudgetPerformanceReport(compareToPrevious: compare));
  }

  void _onToggleComparison(ToggleBudgetComparison event,
      Emitter<BudgetPerformanceReportState> emit) {
    log.info(
        "[BudgetPerformanceReportBloc] Comparison toggled. Reloading report.");
    final bool currentCompare = state is BudgetPerformanceReportLoaded
        ? (state as BudgetPerformanceReportLoaded).showComparison
        : false;
    add(LoadBudgetPerformanceReport(compareToPrevious: !currentCompare));
  }

  Future<void> _onLoadReport(LoadBudgetPerformanceReport event,
      Emitter<BudgetPerformanceReportState> emit) async {
    if (state is BudgetPerformanceReportLoading &&
        (state as BudgetPerformanceReportLoading).compareToPrevious ==
            event.compareToPrevious) {
      log.fine("[BudgetPerformanceReportBloc] Already loading.");
      return;
    }

    emit(BudgetPerformanceReportLoading(
        compareToPrevious: event.compareToPrevious));
    log.info(
        "[BudgetPerformanceReportBloc] Loading budget performance report (Compare: ${event.compareToPrevious})...");

    final filterState = _reportFilterBloc.state;
    // TODO: Allow filtering by specific budget IDs from filter state if needed
    final params = GetBudgetPerformanceReportParams(
      startDate: filterState.startDate,
      endDate: filterState.endDate,
      // budgetIds: filterState.selectedBudgetIds, // Add if budget multi-select is added
      compareToPrevious: event.compareToPrevious,
    );

    final result = await _getReportUseCase(params);

    result.fold(
      (failure) {
        log.warning(
            "[BudgetPerformanceReportBloc] Load failed: ${failure.message}");
        emit(BudgetPerformanceReportError(_mapFailureToMessage(failure)));
      },
      (reportData) {
        log.info(
            "[BudgetPerformanceReportBloc] Load successful. Budgets: ${reportData.performanceData.length}, Comparison: ${reportData.previousPerformanceData != null}");
        emit(BudgetPerformanceReportLoaded(reportData,
            showComparison: event.compareToPrevious));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    return failure.message;
  }

  @override
  Future<void> close() {
    _filterSubscription.cancel();
    log.info(
        "[BudgetPerformanceReportBloc] Closed and cancelled subscription.");
    return super.close();
  }
}
