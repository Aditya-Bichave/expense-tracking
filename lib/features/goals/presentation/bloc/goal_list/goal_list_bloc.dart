// lib/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_goals.dart';
import 'package:expense_tracker/features/goals/domain/usecases/archive_goal.dart'; // Import Archive UseCase
import 'package:expense_tracker/core/di/service_locator.dart'; // Import publishDataChangedEvent
import 'package:expense_tracker/main.dart';

part 'goal_list_event.dart';
part 'goal_list_state.dart';

class GoalListBloc extends Bloc<GoalListEvent, GoalListState> {
  final GetGoalsUseCase _getGoalsUseCase;
  final ArchiveGoalUseCase _archiveGoalUseCase; // Added Archive UseCase
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  GoalListBloc({
    required GetGoalsUseCase getGoalsUseCase,
    required ArchiveGoalUseCase archiveGoalUseCase, // Added requirement
    required Stream<DataChangedEvent> dataChangeStream,
    required Object deleteGoalUseCase,
  })  : _getGoalsUseCase = getGoalsUseCase,
        _archiveGoalUseCase = archiveGoalUseCase, // Assign UseCase
        super(const GoalListState()) {
    on<LoadGoals>(_onLoadGoals);
    on<_GoalsDataChanged>(_onDataChanged);
    on<ArchiveGoal>(_onArchiveGoal); // Register handler

    _dataChangeSubscription = dataChangeStream.listen((event) {
      // Reload goals if Goals or Contributions change
      if (event.type == DataChangeType.goal ||
          event.type == DataChangeType.goalContribution) {
        log.info(
            "[GoalListBloc] Relevant DataChangedEvent ($event). Triggering reload.");
        add(const _GoalsDataChanged());
      }
    });
    log.info("[GoalListBloc] Initialized.");
  }

  Future<void> _onDataChanged(
      _GoalsDataChanged event, Emitter<GoalListState> emit) async {
    // Avoid triggering reload if already loading/reloading
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
    // Prevent duplicate loading unless forced
    if (state.status == GoalListStatus.loading && !event.forceReload) {
      log.fine("[GoalListBloc] LoadGoals ignored, already loading.");
      return;
    }

    log.info(
        "[GoalListBloc] LoadGoals triggered. ForceReload: ${event.forceReload}");
    emit(state.copyWith(status: GoalListStatus.loading, clearError: true));

    // Fetches active goals by default based on UseCase implementation
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

    // Optimistic UI update - remove the item from the current list
    final optimisticList =
        state.goals.where((g) => g.id != event.goalId).toList();
    final optimisticStatus = state.status == GoalListStatus.error
        ? GoalListStatus.success
        : state.status;
    emit(state.copyWith(
        goals: optimisticList,
        status: optimisticStatus, // Assume success during operation
        clearError: true));

    final result =
        await _archiveGoalUseCase(ArchiveGoalParams(id: event.goalId));

    result.fold((failure) {
      log.warning("[GoalListBloc] Archive failed: ${failure.message}");
      // Revert UI implicitly by forcing a reload which will show the error state
      emit(state.copyWith(
          status: GoalListStatus.error,
          errorMessage: _mapFailureToMessage(failure,
              context: "Failed to archive goal")));
      add(const LoadGoals(
          forceReload:
              true)); // Force reload to show error and potentially revert list if needed
    }, (_) {
      log.info("[GoalListBloc] Archive successful for ${event.goalId}.");
      // Publish event - list will reload reactively via _onDataChanged
      publishDataChangedEvent(
          type: DataChangeType.goal,
          reason: DataChangeReason.updated); // Use updated as status changed
      // No need to emit success state here, reactive reload handles it
    });
  }

  String _mapFailureToMessage(Failure failure,
      {String context = "An error occurred"}) {
    log.warning(
        "[GoalListBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message; // Use validation message directly
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
