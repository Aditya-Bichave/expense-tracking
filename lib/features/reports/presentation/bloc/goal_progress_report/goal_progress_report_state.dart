// lib/features/reports/presentation/bloc/goal_progress_report/goal_progress_report_state.dart
part of 'goal_progress_report_bloc.dart';

abstract class GoalProgressReportState extends Equatable {
  const GoalProgressReportState();
  @override
  List<Object?> get props => [];
}

class GoalProgressReportInitial extends GoalProgressReportState {}

class GoalProgressReportLoading extends GoalProgressReportState {}

class GoalProgressReportLoaded extends GoalProgressReportState {
  final GoalProgressReportData reportData;
  const GoalProgressReportLoaded(this.reportData);
  @override
  List<Object?> get props => [reportData];
}

class GoalProgressReportError extends GoalProgressReportState {
  final String message;
  const GoalProgressReportError(this.message);
  @override
  List<Object?> get props => [message];
}
