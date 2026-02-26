// lib/features/goals/presentation/bloc/add_edit_goal/add_edit_goal_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart'; // Import Status
import 'package:expense_tracker/features/goals/domain/usecases/add_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_goal.dart'; // ADDED
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart'; // For ValueGetter
import 'package:uuid/uuid.dart'; // For generating ID

part 'add_edit_goal_event.dart';
part 'add_edit_goal_state.dart';

class AddEditGoalBloc extends Bloc<AddEditGoalEvent, AddEditGoalState> {
  final AddGoalUseCase _addGoalUseCase;
  final UpdateGoalUseCase _updateGoalUseCase; // ADDED

  AddEditGoalBloc({
    required AddGoalUseCase addGoalUseCase,
    required UpdateGoalUseCase updateGoalUseCase, // ADDED
    Goal? initialGoal,
  }) : _addGoalUseCase = addGoalUseCase,
       _updateGoalUseCase = updateGoalUseCase, // ADDED
       super(AddEditGoalState(initialGoal: initialGoal)) {
    on<SaveGoal>(_onSaveGoal);
    on<ClearGoalFormMessage>(_onClearMessage);

    log.info("[AddEditGoalBloc] Initialized. Editing: ${initialGoal != null}");
  }

  Future<void> _onSaveGoal(
    SaveGoal event,
    Emitter<AddEditGoalState> emit,
  ) async {
    log.info("[AddEditGoalBloc] SaveGoal received: ${event.name}");
    emit(state.copyWith(status: AddEditGoalStatus.loading, clearError: true));

    final bool isEditing = state.isEditing;

    // Construct Goal object
    final goalData = Goal(
      id:
          state.initialGoal?.id ??
          sl<Uuid>().v4(), // Use existing ID or generate new
      name: event.name.trim(),
      targetAmount: event.targetAmount,
      targetDate: event.targetDate,
      iconName:
          event.iconName ??
          state.initialGoal?.iconName ??
          'savings', // Preserve or default
      description: event.description?.trim(),
      status: state.initialGoal?.status ?? GoalStatus.active, // Preserve status
      totalSaved:
          state.initialGoal?.totalSaved ?? 0.0, // Preserve cached saved amount
      createdAt: state.initialGoal?.createdAt ?? DateTime.now(),
      achievedAt: state.initialGoal?.achievedAt, // Preserve achievedAt
    );

    // Call appropriate use case
    final result = isEditing
        ? await _updateGoalUseCase(
            UpdateGoalParams(goal: goalData),
          ) // Use Update use case
        : await _addGoalUseCase(
            AddGoalParams(
              // Add params remain the same
              name: goalData.name,
              targetAmount: goalData.targetAmount,
              targetDate: goalData.targetDate,
              iconName: goalData.iconName,
              description: goalData.description,
            ),
          );

    result.fold(
      (failure) {
        log.warning("[AddEditGoalBloc] Save failed: ${failure.message}");
        emit(
          state.copyWith(
            status: AddEditGoalStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
        emit(
          state.copyWith(status: AddEditGoalStatus.initial),
        ); // Revert status after error
      },
      (savedGoal) {
        log.info("[AddEditGoalBloc] Save successful for '${savedGoal.name}'.");
        emit(state.copyWith(status: AddEditGoalStatus.success));
        publishDataChangedEvent(
          type: DataChangeType.goal,
          reason: isEditing ? DataChangeReason.updated : DataChangeReason.added,
        );
      },
    );
  }

  void _onClearMessage(
    ClearGoalFormMessage event,
    Emitter<AddEditGoalState> emit,
  ) {
    if (state.status == AddEditGoalStatus.error ||
        state.status == AddEditGoalStatus.success) {
      emit(state.copyWith(status: AddEditGoalStatus.initial, clearError: true));
    } else {
      emit(state.copyWith(clearError: true));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    log.warning(
      "[AddEditGoalBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}",
    );
    switch (failure) {
      case ValidationFailure _:
        return failure.message;
      case CacheFailure _:
        return 'Database Error: ${failure.message}';
      default:
        return 'An unexpected error occurred saving the goal.';
    }
  }
}
