// lib/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_goals.dart';
import 'package:expense_tracker/features/goals/domain/usecases/archive_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/delete_goal.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/main.dart';

part 'goal_list_event.dart';
part 'goal_list_state.dart';

class GoalListBloc extends Bloc<GoalListEvent, GoalListState> {
  final GetGoalsUseCase _getGoalsUseCase;
  final ArchiveGoalUseCase _archiveGoalUseCase;
  final DeleteGoalUseCase _deleteGoalUseCase;

  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  GoalListBloc({
    required GetGoalsUseCase getGoalsUseCase,
    required ArchiveGoalUseCase archiveGoalUseCase,
    required Stream<DataChangedEvent> dataChangeStream,
    required DeleteGoalUseCase deleteGoalUseCase,
  })  : _getGoalsUseCase = getGoalsUseCase,
        _archiveGoalUseCase = archiveGoalUseCase,
        _deleteGoalUseCase = deleteGoalUseCase,
        super(const GoalListState()) {
    on<LoadGoals>(_onLoadGoals);
    on<_GoalsDataChanged>(_onDataChanged);
    on<ArchiveGoal>(_onArchiveGoal);
    on<DeleteGoal>(_onDeleteGoal);
    on<ResetState>(_onResetState); // Add handler

    _dataChangeSubscription = dataChangeStream.listen((event) {
      // --- MODIFIED Listener ---
      if (event.type == DataChangeType.system &&
          event.reason == DataChangeReason.reset) {
        log.info(
            "[GoalListBloc] System Reset event received. Adding ResetState.");
        add(const ResetState());
      } else if (event.type == DataChangeType.goal ||
          event.type == DataChangeType.goalContribution) {
        log.info(
            "[GoalListBloc] Relevant DataChangedEvent ($event). Triggering reload.");
        add(const _GoalsDataChanged());
      }
      // --- END MODIFIED ---
    });
    log.info("[GoalListBloc] Initialized.");
  }

  // --- ADDED: Reset State Handler ---
  void _onResetState(ResetState event, Emitter<GoalListState> emit) {
    log.info("[GoalListBloc] Resetting state to initial.");
    emit(const GoalListState());
    add(const LoadGoals()); // Trigger initial load after reset
  }
  // --- END ADDED ---

  // ... (rest of handlers remain the same) ...
  Future<void> _onDataChanged(
      _GoalsDataChanged event, Emitter<GoalListState> emit) async {
    if (state.status != GoalListStatus.loading) {
      log.fine("[GoalListBloc] Handling _DataChanged event.");
      add(const LoadGoals(forceReload: true));
    } else {
      log.fine(
          "[GoalListBloc] _DataChanged received, but already loading. Skipping explicit reload.");
    }
  }

  Future<void> _onLoadGoals(
      LoadGoals event, Emitter<GoalListState> emit) async {
    if (state.status == GoalListStatus.loading && !event.forceReload) {
      log.fine("[GoalListBloc] LoadGoals ignored, already loading.");
      return;
    }
    log.info(
        "[GoalListBloc] LoadGoals triggered. ForceReload: ${event.forceReload}");
    emit(state.copyWith(status: GoalListStatus.loading, clearError: true));
    final result = await _getGoalsUseCase(const NoParams());
    result.fold(
      (failure) {
        log.warning("[GoalListBloc] Failed to load goals: ${failure.message}");
        emit(state.copyWith(
            status: GoalListStatus.error,
            errorMessage: _mapFailureToMessage(failure)));
      },
      (goals) {
        log.info("[GoalListBloc] Loaded ${goals.length} active goals.");
        emit(state.copyWith(
          status: GoalListStatus.success,
          goals: goals,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onArchiveGoal(
      ArchiveGoal event, Emitter<GoalListState> emit) async {
    log.info("[GoalListBloc] ArchiveGoal triggered for ID: ${event.goalId}");
    final optimisticList =
        state.goals.where((g) => g.id != event.goalId).toList();
    final optimisticStatus = state.status == GoalListStatus.error
        ? GoalListStatus.success
        : state.status;
    emit(state.copyWith(
        goals: optimisticList, status: optimisticStatus, clearError: true));
    final result =
        await _archiveGoalUseCase(ArchiveGoalParams(id: event.goalId));
    result.fold(
      (failure) {
        log.warning("[GoalListBloc] Archive failed: ${failure.message}");
        emit(state.copyWith(
            status: GoalListStatus.error,
            errorMessage: _mapFailureToMessage(failure,
                context: "Failed to archive goal")));
        add(const LoadGoals(forceReload: true));
      },
      (_) {
        log.info("[GoalListBloc] Archive successful for ${event.goalId}.");
        publishDataChangedEvent(
            type: DataChangeType.goal, reason: DataChangeReason.updated);
      },
    );
  }

  Future<void> _onDeleteGoal(
      DeleteGoal event, Emitter<GoalListState> emit) async {
    log.info("[GoalListBloc] DeleteGoal triggered for ID: ${event.goalId}");
    final optimisticList =
        state.goals.where((g) => g.id != event.goalId).toList();
    final optimisticStatus = state.status == GoalListStatus.error
        ? GoalListStatus.success
        : state.status;
    emit(state.copyWith(
        goals: optimisticList, status: optimisticStatus, clearError: true));
    final result = await _deleteGoalUseCase(DeleteGoalParams(id: event.goalId));
    result.fold(
      (failure) {
        log.warning("[GoalListBloc] Delete failed: ${failure.message}");
        emit(state.copyWith(
            status: GoalListStatus.error,
            errorMessage: _mapFailureToMessage(failure,
                context: "Failed to delete goal")));
        add(const LoadGoals(forceReload: true)); // Revert/Reload
      },
      (_) {
        log.info("[GoalListBloc] Delete successful for ${event.goalId}.");
        publishDataChangedEvent(
            type: DataChangeType.goal, reason: DataChangeReason.deleted);
      },
    );
  }

  String _mapFailureToMessage(Failure failure,
      {String context = "An error occurred"}) {
    log.warning(
        "[GoalListBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message;
      case CacheFailure:
        return '$context: Database Error: ${failure.message}';
      default:
        return '$context: An unexpected error occurred.';
    }
  }

  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    log.info("[GoalListBloc] Closed and cancelled data stream subscription.");
    return super.close();
  }
}
