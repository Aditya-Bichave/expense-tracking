// lib/features/goals/presentation/bloc/goal_list/goal_list_event.dart
part of 'goal_list_bloc.dart';

abstract class GoalListEvent extends Equatable {
  const GoalListEvent();
  @override
  List<Object> get props => [];
}

class LoadGoals extends GoalListEvent {
  final bool forceReload;
  const LoadGoals({this.forceReload = false});
  @override
  List<Object> get props => [forceReload];
}

class _GoalsDataChanged extends GoalListEvent {
  const _GoalsDataChanged();
}

class ArchiveGoal extends GoalListEvent {
  final String goalId;
  const ArchiveGoal({required this.goalId});
  @override
  List<Object> get props => [goalId];
}

class DeleteGoal extends GoalListEvent {
  final String goalId;
  const DeleteGoal({required this.goalId});
  @override
  List<Object> get props => [goalId];
}

// --- ADDED: Reset State Event ---
class ResetState extends GoalListEvent {
  const ResetState();
}

// --- END ADDED ---
