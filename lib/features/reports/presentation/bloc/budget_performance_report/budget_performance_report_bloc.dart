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
  }) : _getReportUseCase = getBudgetPerformanceReportUseCase,
       _reportFilterBloc = reportFilterBloc,
       super(BudgetPerformanceReportInitial()) {
    on<LoadBudgetPerformanceReport>(_onLoadReport);
    on<ToggleBudgetComparison>(_onToggleComparison);
    on<_FilterChanged>(_onFilterChanged);

    _filterSubscription = _reportFilterBloc.stream.listen((filterState) {
      // Reload when filters change, preserving the current comparison state
      final bool compare = state is BudgetPerformanceReportLoaded
          ? (state as BudgetPerformanceReportLoaded).showComparison
          : false;
      add(
        LoadBudgetPerformanceReport(
          compareToPrevious: compare,
          forceReload: true,
        ),
      );
    });

    log.info("[BudgetPerformanceReportBloc] Initialized.");
    add(const LoadBudgetPerformanceReport()); // Initial load without comparison
  }

  void _onFilterChanged(
    _FilterChanged event,
    Emitter<BudgetPerformanceReportState> emit,
  ) {
    log.info(
      "[BudgetPerformanceReportBloc] Filter changed detected, reloading report.",
    );
    // Get current comparison state before reloading
    final bool compare = state is BudgetPerformanceReportLoaded
        ? (state as BudgetPerformanceReportLoaded).showComparison
        : false;
    add(
      LoadBudgetPerformanceReport(
        compareToPrevious: compare,
        forceReload: true,
      ),
    );
  }

  void _onToggleComparison(
    ToggleBudgetComparison event,
    Emitter<BudgetPerformanceReportState> emit,
  ) {
    log.info(
      "[BudgetPerformanceReportBloc] Comparison toggled. Reloading report.",
    );
    final bool currentCompare = state is BudgetPerformanceReportLoaded
        ? (state as BudgetPerformanceReportLoaded).showComparison
        : false;
    // Dispatch load event with the *toggled* comparison value
    add(LoadBudgetPerformanceReport(compareToPrevious: !currentCompare));
  }

  Future<void> _onLoadReport(
    LoadBudgetPerformanceReport event,
    Emitter<BudgetPerformanceReportState> emit,
  ) async {
    // Avoid duplicate loads for the same comparison state unless forced
    if (!event.forceReload &&
        state is BudgetPerformanceReportLoading &&
        (state as BudgetPerformanceReportLoading).compareToPrevious ==
            event.compareToPrevious) {
      log.fine(
        "[BudgetPerformanceReportBloc] Already loading for comparison state: ${event.compareToPrevious}",
      );
      return;
    }

    emit(
      BudgetPerformanceReportLoading(
        compareToPrevious: event.compareToPrevious,
      ),
    );
    log.info(
      "[BudgetPerformanceReportBloc] Loading budget performance report (Compare: ${event.compareToPrevious})...",
    );

    final filterState = _reportFilterBloc.state;
    final params = GetBudgetPerformanceReportParams(
      startDate: filterState.startDate,
      endDate: filterState.endDate,
      budgetIds: filterState.selectedBudgetIds.isEmpty
          ? null
          : filterState.selectedBudgetIds,
      accountIds: filterState.selectedAccountIds.isEmpty
          ? null
          : filterState.selectedAccountIds,
      compareToPrevious: event.compareToPrevious, // Use event flag
    );

    final result = await _getReportUseCase(params);

    result.fold(
      (failure) {
        log.warning(
          "[BudgetPerformanceReportBloc] Load failed: ${failure.message}",
        );
        emit(BudgetPerformanceReportError(_mapFailureToMessage(failure)));
      },
      (reportData) {
        log.info(
          "[BudgetPerformanceReportBloc] Load successful. Budgets: ${reportData.performanceData.length}, Comparison data present: ${reportData.previousPerformanceData != null}",
        );
        // Pass both report data and the comparison flag used for this load
        emit(
          BudgetPerformanceReportLoaded(
            reportData,
            showComparison: event.compareToPrevious,
          ),
        );
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    return failure.message; // Basic mapping
  }

  @override
  Future<void> close() {
    _filterSubscription.cancel();
    log.info(
      "[BudgetPerformanceReportBloc] Closed and cancelled subscription.",
    );
    return super.close();
  }
}
