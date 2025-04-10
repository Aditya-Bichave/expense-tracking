// lib/features/reports/presentation/bloc/goal_progress_report/goal_progress_report_event.dart
part of 'goal_progress_report_bloc.dart';

abstract class GoalProgressReportEvent extends Equatable {
  const GoalProgressReportEvent();
  @override
  List<Object?> get props => [];
}

class LoadGoalProgressReport extends GoalProgressReportEvent {
  // Optional: Add flags for comparison later
  const LoadGoalProgressReport();
}

// Internal event for filter changes
class _FilterChanged extends GoalProgressReportEvent {
  const _FilterChanged();
}
