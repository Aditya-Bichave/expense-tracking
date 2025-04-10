// lib/features/reports/presentation/bloc/spending_category_report/spending_category_report_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_category_report.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart'; // Listen to filter changes
import 'package:expense_tracker/main.dart';

part 'spending_category_report_event.dart';
part 'spending_category_report_state.dart';

class SpendingCategoryReportBloc
    extends Bloc<SpendingCategoryReportEvent, SpendingCategoryReportState> {
  final GetSpendingCategoryReportUseCase _getReportUseCase;
  final ReportFilterBloc _reportFilterBloc; // Inject filter bloc
  late final StreamSubscription _filterSubscription;

  SpendingCategoryReportBloc({
    required GetSpendingCategoryReportUseCase getSpendingCategoryReportUseCase,
    required ReportFilterBloc reportFilterBloc, // Require filter bloc
  })  : _getReportUseCase = getSpendingCategoryReportUseCase,
        _reportFilterBloc = reportFilterBloc,
        super(SpendingCategoryReportInitial()) {
    on<LoadSpendingCategoryReport>(_onLoadReport);
    on<_FilterChanged>(_onFilterChanged); // Internal event

    // Listen to the filter bloc's state changes
    _filterSubscription = _reportFilterBloc.stream.listen((filterState) {
      // Trigger report reload when relevant filters change
      add(const _FilterChanged());
    });

    log.info("[SpendingCategoryReportBloc] Initialized.");
    // Trigger initial load based on initial filter state
    add(const LoadSpendingCategoryReport());
  }

  void _onFilterChanged(
      _FilterChanged event, Emitter<SpendingCategoryReportState> emit) {
    log.info(
        "[SpendingCategoryReportBloc] Filter changed detected, reloading report.");
    add(const LoadSpendingCategoryReport()); // Trigger load with current filters
  }

  Future<void> _onLoadReport(LoadSpendingCategoryReport event,
      Emitter<SpendingCategoryReportState> emit) async {
    if (state is SpendingCategoryReportLoading)
      return; // Avoid concurrent loads

    emit(SpendingCategoryReportLoading());
    log.info(
        "[SpendingCategoryReportBloc] Loading spending by category report...");

    // Get current filters from the injected filter bloc
    final filterState = _reportFilterBloc.state;
    final params = GetSpendingCategoryReportParams(
      startDate: filterState.startDate,
      endDate: filterState.endDate,
      accountIds: filterState.selectedAccountIds.isEmpty
          ? null
          : filterState.selectedAccountIds,
    );

    final result = await _getReportUseCase(params);

    result.fold(
      (failure) {
        log.warning(
            "[SpendingCategoryReportBloc] Load failed: ${failure.message}");
        emit(SpendingCategoryReportError(_mapFailureToMessage(failure)));
      },
      (reportData) {
        log.info(
            "[SpendingCategoryReportBloc] Load successful. Total: ${reportData.totalSpending}, Categories: ${reportData.spendingByCategory.length}");
        emit(SpendingCategoryReportLoaded(reportData));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    // Basic mapping
    return failure.message;
  }

  @override
  Future<void> close() {
    _filterSubscription
        .cancel(); // Important: Cancel subscription when bloc closes
    log.info("[SpendingCategoryReportBloc] Closed and cancelled subscription.");
    return super.close();
  }
}
