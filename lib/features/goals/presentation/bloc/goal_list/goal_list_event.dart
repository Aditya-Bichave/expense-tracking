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

// --- ADDED Archive Event ---
class ArchiveGoal extends GoalListEvent {
  final String goalId;
  const ArchiveGoal({required this.goalId});
  @override
  List<Object> get props => [goalId];
}
// --- END Archive Event ---

// Delete event if implementing permanent delete
// class DeleteGoal extends GoalListEvent { ... }
