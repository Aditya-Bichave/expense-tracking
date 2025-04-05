// lib/features/goals/presentation/bloc/log_contribution/log_contribution_state.dart
part of 'log_contribution_bloc.dart';

enum LogContributionStatus { initial, loading, success, error }

class LogContributionState extends Equatable {
  final LogContributionStatus status;
  final String goalId; // ID of the goal being contributed to
  final GoalContribution? initialContribution; // Contribution being edited
  final String? errorMessage;

  const LogContributionState({
    this.status = LogContributionStatus.initial,
    required this.goalId,
    this.initialContribution,
    this.errorMessage,
  });

  // Initial state factory
  factory LogContributionState.initial(String goalId) {
    return LogContributionState(goalId: goalId);
  }

  bool get isEditing => initialContribution != null;

  LogContributionState copyWith({
    LogContributionStatus? status,
    String? goalId, // Should generally not change after init
    GoalContribution? initialContribution,
    ValueGetter<GoalContribution?>? initialContributionOrNull,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LogContributionState(
      status: status ?? this.status,
      goalId: goalId ?? this.goalId,
      initialContribution: initialContributionOrNull != null
          ? initialContributionOrNull()
          : (initialContribution ?? this.initialContribution),
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, goalId, initialContribution, errorMessage];
}
