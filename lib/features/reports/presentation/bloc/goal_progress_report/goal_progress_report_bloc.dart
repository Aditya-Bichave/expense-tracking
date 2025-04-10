// lib/features/reports/presentation/bloc/goal_progress_report/goal_progress_report_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_goal_progress_report.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/main.dart';

part 'goal_progress_report_event.dart';
part 'goal_progress_report_state.dart';

class GoalProgressReportBloc
    extends Bloc<GoalProgressReportEvent, GoalProgressReportState> {
  final GetGoalProgressReportUseCase _getReportUseCase;
  final ReportFilterBloc _reportFilterBloc;
  late final StreamSubscription _filterSubscription;

  GoalProgressReportBloc({
    required GetGoalProgressReportUseCase getGoalProgressReportUseCase,
    required ReportFilterBloc reportFilterBloc,
  })  : _getReportUseCase = getGoalProgressReportUseCase,
        _reportFilterBloc = reportFilterBloc,
        super(GoalProgressReportInitial()) {
    on<LoadGoalProgressReport>(_onLoadReport);
    on<_FilterChanged>(_onFilterChanged);

    _filterSubscription = _reportFilterBloc.stream.listen((filterState) {
      // Reload if the selected goal IDs change
      // We need to compare the current bloc state's filter IDs with the new ones
      // This simple listener might trigger too often if other filters change.
      // A more robust solution would check if specifically selectedGoalIds changed.
      add(const _FilterChanged());
    });

    log.info("[GoalProgressReportBloc] Initialized.");
    add(const LoadGoalProgressReport()); // Initial load
  }

  void _onFilterChanged(
      _FilterChanged event, Emitter<GoalProgressReportState> emit) {
    log.info(
        "[GoalProgressReportBloc] Filter changed detected, reloading report.");
    add(const LoadGoalProgressReport());
  }

  Future<void> _onLoadReport(LoadGoalProgressReport event,
      Emitter<GoalProgressReportState> emit) async {
    if (state is GoalProgressReportLoading) return;

    emit(GoalProgressReportLoading());
    log.info("[GoalProgressReportBloc] Loading goal progress report...");

    // Get selected goals from filter state
    final filterState = _reportFilterBloc.state;
    final params = GetGoalProgressReportParams(
      // --- FIXED: Access selectedGoalIds correctly ---
      goalIds: filterState.selectedGoalIds.isEmpty
          ? null
          : filterState.selectedGoalIds,
      // --- END FIX ---
      // calculateComparisonRate: // Add flag if comparison is implemented
    );

    final result = await _getReportUseCase(params);

    result.fold(
      (failure) {
        log.warning("[GoalProgressReportBloc] Load failed: ${failure.message}");
        emit(GoalProgressReportError(_mapFailureToMessage(failure)));
      },
      (reportData) {
        log.info(
            "[GoalProgressReportBloc] Load successful. Goals: ${reportData.progressData.length}");
        emit(GoalProgressReportLoaded(reportData));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    return failure.message;
  }

  @override
  Future<void> close() {
    _filterSubscription.cancel();
    log.info("[GoalProgressReportBloc] Closed and cancelled subscription.");
    return super.close();
  }
}
