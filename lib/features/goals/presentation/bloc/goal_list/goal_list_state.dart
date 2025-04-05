// lib/features/goals/presentation/bloc/goal_list/goal_list_state.dart
part of 'goal_list_bloc.dart';

enum GoalListStatus { initial, loading, success, error }

class GoalListState extends Equatable {
  final GoalListStatus status;
  final List<Goal> goals; // Holds active goals by default
  final String? errorMessage;

  const GoalListState({
    this.status = GoalListStatus.initial,
    this.goals = const [],
    this.errorMessage,
  });

  GoalListState copyWith({
    GoalListStatus? status,
    List<Goal>? goals,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GoalListState(
      status: status ?? this.status,
      goals: goals ?? this.goals,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, goals, errorMessage];
}
