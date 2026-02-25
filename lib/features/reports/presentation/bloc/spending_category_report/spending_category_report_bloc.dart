// lib/features/reports/presentation/bloc/spending_category_report/spending_category_report_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_category_report.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/utils/logger.dart';

part 'spending_category_report_event.dart';
part 'spending_category_report_state.dart';

class SpendingCategoryReportBloc
    extends Bloc<SpendingCategoryReportEvent, SpendingCategoryReportState> {
  final GetSpendingCategoryReportUseCase _getReportUseCase;
  final ReportFilterBloc _reportFilterBloc;
  late final StreamSubscription _filterSubscription;

  SpendingCategoryReportBloc({
    required GetSpendingCategoryReportUseCase getSpendingCategoryReportUseCase,
    required ReportFilterBloc reportFilterBloc,
  }) : _getReportUseCase = getSpendingCategoryReportUseCase,
       _reportFilterBloc = reportFilterBloc,
       super(SpendingCategoryReportInitial()) {
    on<LoadSpendingCategoryReport>(_onLoadReport);
    on<ToggleSpendingComparison>(
      _onToggleComparison,
    ); // Use specific toggle event
    on<_FilterChanged>(_onFilterChanged);

    _filterSubscription = _reportFilterBloc.stream.listen((filterState) {
      add(const _FilterChanged());
    });

    log.info("[SpendingCategoryReportBloc] Initialized.");
    add(const LoadSpendingCategoryReport()); // Initial load without comparison
  }

  void _onFilterChanged(
    _FilterChanged event,
    Emitter<SpendingCategoryReportState> emit,
  ) {
    log.info(
      "[SpendingCategoryReportBloc] Filter changed detected, reloading report.",
    );
    // Get current comparison state before reloading
    final bool compare = state is SpendingCategoryReportLoaded
        ? (state as SpendingCategoryReportLoaded).showComparison
        : false;
    add(LoadSpendingCategoryReport(compareToPrevious: compare));
  }

  void _onToggleComparison(
    ToggleSpendingComparison event,
    Emitter<SpendingCategoryReportState> emit,
  ) {
    log.info(
      "[SpendingCategoryReportBloc] Comparison toggled. Reloading report.",
    );
    final bool currentCompare = state is SpendingCategoryReportLoaded
        ? (state as SpendingCategoryReportLoaded).showComparison
        : false;
    // Dispatch load event with the *toggled* comparison value
    add(LoadSpendingCategoryReport(compareToPrevious: !currentCompare));
  }

  Future<void> _onLoadReport(
    LoadSpendingCategoryReport event,
    Emitter<SpendingCategoryReportState> emit,
  ) async {
    // Avoid duplicate loads for the same comparison state
    if (state is SpendingCategoryReportLoading &&
        (state as SpendingCategoryReportLoading).compareToPrevious ==
            event.compareToPrevious) {
      log.fine(
        "[SpendingCategoryReportBloc] Already loading for comparison state: ${event.compareToPrevious}",
      );
      return;
    }

    emit(
      SpendingCategoryReportLoading(compareToPrevious: event.compareToPrevious),
    ); // Pass compare flag
    log.info(
      "[SpendingCategoryReportBloc] Loading spending by category report (Compare: ${event.compareToPrevious})...",
    );

    final filterState = _reportFilterBloc.state;
    final params = GetSpendingCategoryReportParams(
      startDate: filterState.startDate,
      endDate: filterState.endDate,
      accountIds: filterState.selectedAccountIds.isEmpty
          ? null
          : filterState.selectedAccountIds,
      categoryIds: filterState.selectedCategoryIds.isEmpty
          ? null
          : filterState.selectedCategoryIds, // Use category filter
      transactionType:
          filterState.selectedTransactionType, // Use transaction type filter
      compareToPrevious: event.compareToPrevious, // Pass flag to use case
    );

    final result = await _getReportUseCase(params);

    result.fold(
      (failure) {
        log.warning(
          "[SpendingCategoryReportBloc] Load failed: ${failure.message}",
        );
        emit(SpendingCategoryReportError(_mapFailureToMessage(failure)));
      },
      (reportData) {
        log.info(
          "[SpendingCategoryReportBloc] Load successful. Total: ${reportData.currentTotalSpending}, Categories: ${reportData.spendingByCategory.length}, Comparison: ${reportData.previousSpendingByCategory != null}",
        );
        // Pass the comparison flag used for this load to the loaded state
        emit(
          SpendingCategoryReportLoaded(
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
    log.info("[SpendingCategoryReportBloc] Closed and cancelled subscription.");
    return super.close();
  }
}
