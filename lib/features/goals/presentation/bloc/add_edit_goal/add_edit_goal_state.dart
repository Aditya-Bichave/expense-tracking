// lib/features/goals/presentation/bloc/add_edit_goal/add_edit_goal_state.dart
part of 'add_edit_goal_bloc.dart';

enum AddEditGoalStatus { initial, loading, success, error }

class AddEditGoalState extends Equatable {
  final AddEditGoalStatus status;
  final Goal? initialGoal; // Goal being edited
  final String? errorMessage;

  const AddEditGoalState({
    this.status = AddEditGoalStatus.initial,
    this.initialGoal,
    this.errorMessage,
  });

  bool get isEditing => initialGoal != null;

  AddEditGoalState copyWith({
    AddEditGoalStatus? status,
    Goal? initialGoal,
    ValueGetter<Goal?>? initialGoalOrNull,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddEditGoalState(
      status: status ?? this.status,
      initialGoal: initialGoalOrNull != null
          ? initialGoalOrNull()
          : (initialGoal ?? this.initialGoal),
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, initialGoal, errorMessage];
}
