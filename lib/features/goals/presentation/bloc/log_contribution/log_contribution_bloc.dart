// lib/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_contribution.dart'; // Import Update UseCase
import 'package:expense_tracker/features/goals/domain/usecases/delete_contribution.dart'; // Import Delete UseCase
import 'package:expense_tracker/features/goals/domain/usecases/check_goal_achievement.dart'; // Import Check Achievement UseCase
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart'; // For ValueGetter
import 'package:uuid/uuid.dart'; // For new contribution ID

part 'log_contribution_event.dart';
part 'log_contribution_state.dart';

class LogContributionBloc
    extends Bloc<LogContributionEvent, LogContributionState> {
  final AddContributionUseCase _addContributionUseCase;
  final UpdateContributionUseCase _updateContributionUseCase; // Added
  final DeleteContributionUseCase _deleteContributionUseCase; // Added
  final CheckGoalAchievementUseCase _checkGoalAchievementUseCase; // Added

  LogContributionBloc({
    required AddContributionUseCase addContributionUseCase,
    required UpdateContributionUseCase updateContributionUseCase, // Added
    required DeleteContributionUseCase deleteContributionUseCase, // Added
    required CheckGoalAchievementUseCase checkGoalAchievementUseCase, // Added
  }) : _addContributionUseCase = addContributionUseCase,
       _updateContributionUseCase = updateContributionUseCase, // Added
       _deleteContributionUseCase = deleteContributionUseCase, // Added
       _checkGoalAchievementUseCase = checkGoalAchievementUseCase, // Added
       super(LogContributionState.initial('')) {
    // Initial state needs a dummy goalId
    on<InitializeContribution>(_onInitializeContribution);
    on<SaveContribution>(_onSaveContribution);
    on<DeleteContribution>(_onDeleteContribution); // Register handler
    on<ClearContributionMessage>(_onClearMessage);

    log.info("[LogContributionBloc] Initialized.");
  }

  void _onInitializeContribution(
    InitializeContribution event,
    Emitter<LogContributionState> emit,
  ) {
    log.info(
      "[LogContributionBloc] Initializing form for Goal ID: ${event.goalId}, Editing: ${event.initialContribution != null}",
    );
    // Reset the state completely based on the initialization event
    emit(
      LogContributionState(
        goalId: event.goalId,
        initialContribution: event.initialContribution,
        status: LogContributionStatus.initial, // Ensure status is initial
      ),
    );
  }

  Future<void> _onSaveContribution(
    SaveContribution event,
    Emitter<LogContributionState> emit,
  ) async {
    final bool isEditing = state.isEditing;
    final String goalId =
        state.goalId; // Capture goalId before potential state changes
    log.info(
      "[LogContributionBloc] SaveContribution received for Goal ID: $goalId. Editing: $isEditing",
    );
    emit(
      state.copyWith(status: LogContributionStatus.loading, clearError: true),
    );

    // Construct the contribution object
    final contributionData = GoalContribution(
      id:
          state.initialContribution?.id ??
          sl<Uuid>().v4(), // Use existing or new ID
      goalId: goalId, // Use captured goalId
      amount: event.amount,
      date: event.date,
      note: event.note?.trim(),
      createdAt:
          state.initialContribution?.createdAt ??
          DateTime.now(), // Preserve original createdAt
    );

    // Call the appropriate use case
    final result = isEditing
        ? await _updateContributionUseCase(
            UpdateContributionParams(contribution: contributionData),
          )
        : await _addContributionUseCase(
            AddContributionParams(
              // Add params remain same
              goalId: contributionData.goalId,
              amount: contributionData.amount,
              date: contributionData.date,
              note: contributionData.note,
            ),
          );

    await result.fold(
      (failure) async {
        log.warning("[LogContributionBloc] Save failed: ${failure.message}");
        emit(
          state.copyWith(
            status: LogContributionStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
      },
      (savedContribution) async {
        log.info(
          "[LogContributionBloc] Contribution saved/updated successfully (ID: ${savedContribution.id}). Checking goal achievement...",
        );

        publishDataChangedEvent(
          type: DataChangeType.goalContribution,
          reason: isEditing ? DataChangeReason.updated : DataChangeReason.added,
        );

        final checkResult = await _checkGoalAchievementUseCase(
          CheckGoalParams(goalId: goalId),
        );
        checkResult.fold(
          (failure) => log.warning(
            "[LogContributionBloc] Achievement check failed after saving contribution: ${failure.message}",
          ),
          (didAchieve) {
            if (didAchieve) {
              log.info(
                "[LogContributionBloc] Goal $goalId was newly achieved!",
              );
              publishDataChangedEvent(
                type: DataChangeType.goal,
                reason: DataChangeReason.updated,
              );
            }
          },
        );

        emit(state.copyWith(status: LogContributionStatus.success));
      },
    );
  }

  Future<void> _onDeleteContribution(
    DeleteContribution event,
    Emitter<LogContributionState> emit,
  ) async {
    // This event should only be called when editing an existing contribution
    if (!state.isEditing || state.initialContribution == null) {
      log.warning(
        "[LogContributionBloc] DeleteContribution called but not in editing state or initialContribution is null.",
      );
      emit(
        state.copyWith(
          status: LogContributionStatus.error,
          errorMessage: "Cannot delete unsaved contribution.",
        ),
      );
      return;
    }
    final contributionId = state.initialContribution!.id;
    final goalId =
        state.initialContribution!.goalId; // Need goalId for achievement check
    log.info(
      "[LogContributionBloc] DeleteContribution received for Contribution ID: $contributionId",
    );
    emit(
      state.copyWith(status: LogContributionStatus.loading, clearError: true),
    );

    final result = await _deleteContributionUseCase(
      DeleteContributionParams(id: contributionId),
    );

    await result.fold(
      (failure) async {
        log.warning("[LogContributionBloc] Delete failed: ${failure.message}");
        emit(
          state.copyWith(
            status: LogContributionStatus.error,
            errorMessage: _mapFailureToMessage(
              failure,
              context: "Failed to delete contribution",
            ),
          ),
        );
      },
      (_) async {
        log.info(
          "[LogContributionBloc] Contribution deleted successfully (ID: $contributionId). Checking goal status...",
        );

        publishDataChangedEvent(
          type: DataChangeType.goalContribution,
          reason: DataChangeReason.deleted,
        );

        final checkResult = await _checkGoalAchievementUseCase(
          CheckGoalParams(goalId: goalId),
        );
        checkResult.fold(
          (failure) => log.warning(
            "[LogContributionBloc] Achievement check failed after deleting contribution: ${failure.message}",
          ),
          (_) {
            log.fine(
              "[LogContributionBloc] Goal status potentially updated after contribution deletion.",
            );
            publishDataChangedEvent(
              type: DataChangeType.goal,
              reason: DataChangeReason.updated,
            );
          },
        );

        emit(state.copyWith(status: LogContributionStatus.success));
      },
    );
  }

  void _onClearMessage(
    ClearContributionMessage event,
    Emitter<LogContributionState> emit,
  ) {
    // Always reset to initial status when clearing message
    emit(
      state.copyWith(status: LogContributionStatus.initial, clearError: true),
    );
  }

  String _mapFailureToMessage(
    Failure failure, {
    String context = "An error occurred",
  }) {
    log.warning(
      "[LogContributionBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}",
    );
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message;
      case CacheFailure:
        return '$context: Database Error: ${failure.message}';
      default:
        return '$context: An unexpected error occurred.';
    }
  }
}
