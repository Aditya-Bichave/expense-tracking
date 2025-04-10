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
  })  : _getReportUseCase = getIncomeExpenseReportUseCase,
        _reportFilterBloc = reportFilterBloc,
        super(IncomeExpenseReportInitial()) {
    on<LoadIncomeExpenseReport>(_onLoadReport);
    on<ChangeIncomeExpensePeriod>(_onChangePeriod);
    on<_FilterChanged>(_onFilterChanged);

    _filterSubscription = _reportFilterBloc.stream.listen((filterState) {
      add(const _FilterChanged());
    });

    log.info("[IncomeExpenseReportBloc] Initialized.");
    add(const LoadIncomeExpenseReport()); // Initial load
  }

  void _onFilterChanged(
      _FilterChanged event, Emitter<IncomeExpenseReportState> emit) {
    log.info(
        "[IncomeExpenseReportBloc] Filter changed detected, reloading report.");
    add(LoadIncomeExpenseReport(
        periodType: state is IncomeExpenseReportLoaded
            ? (state as IncomeExpenseReportLoaded).reportData.periodType
            : IncomeExpensePeriodType.monthly // Default if not loaded yet
        ));
  }

  void _onChangePeriod(
      ChangeIncomeExpensePeriod event, Emitter<IncomeExpenseReportState> emit) {
    log.info(
        "[IncomeExpenseReportBloc] Period changed to ${event.periodType}. Reloading.");
    add(LoadIncomeExpenseReport(periodType: event.periodType));
  }

  Future<void> _onLoadReport(LoadIncomeExpenseReport event,
      Emitter<IncomeExpenseReportState> emit) async {
    final currentPeriodType = event.periodType ??
        (state is IncomeExpenseReportLoaded
            ? (state as IncomeExpenseReportLoaded).reportData.periodType
            : IncomeExpensePeriodType.monthly);

    if (state is IncomeExpenseReportLoading &&
        (state as IncomeExpenseReportLoading).periodType == currentPeriodType) {
      log.fine(
          "[IncomeExpenseReportBloc] Already loading with same period type.");
      return;
    }

    emit(IncomeExpenseReportLoading(periodType: currentPeriodType));
    log.info(
        "[IncomeExpenseReportBloc] Loading Income vs Expense report (Period: $currentPeriodType)...");

    final filterState = _reportFilterBloc.state;
    final params = GetIncomeExpenseReportParams(
      startDate: filterState.startDate,
      endDate: filterState.endDate,
      periodType: currentPeriodType,
      accountIds: filterState.selectedAccountIds.isEmpty
          ? null
          : filterState.selectedAccountIds,
    );

    final result = await _getReportUseCase(params);

    result.fold(
      (failure) {
        log.warning(
            "[IncomeExpenseReportBloc] Load failed: ${failure.message}");
        emit(IncomeExpenseReportError(_mapFailureToMessage(failure)));
      },
      (reportData) {
        log.info(
            "[IncomeExpenseReportBloc] Load successful. Period: ${reportData.periodType}, Points: ${reportData.periodData.length}");
        emit(IncomeExpenseReportLoaded(reportData));
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
