part of 'add_edit_goal_bloc.dart';

enum AddEditGoalStatus { initial, loading, success, error }

class AddEditGoalState extends Equatable {
  final AddEditGoalStatus status;
  final Goal? initialGoal;
  final String? errorMessage;
  final bool clearError;

  const AddEditGoalState({
    this.status = AddEditGoalStatus.initial,
    this.initialGoal,
    this.errorMessage,
    this.clearError = false,
  });

  bool get isEditing => initialGoal != null;

  AddEditGoalState copyWith({
    AddEditGoalStatus? status,
    Goal? initialGoal,
    String? errorMessage,
    bool? clearError,
  }) {
    return AddEditGoalState(
      status: status ?? this.status,
      initialGoal: initialGoal ?? this.initialGoal,
      errorMessage: errorMessage ?? this.errorMessage,
      clearError: clearError ?? this.clearError,
    );
  }

  @override
  List<Object?> get props => [status, initialGoal, errorMessage, clearError];
}
