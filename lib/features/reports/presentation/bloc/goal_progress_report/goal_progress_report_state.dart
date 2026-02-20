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
  final bool isComparisonEnabled;

  const GoalProgressReportLoaded(
    this.reportData, {
    this.isComparisonEnabled = false,
  });

  @override
  List<Object?> get props => [reportData, isComparisonEnabled];
}

class GoalProgressReportError extends GoalProgressReportState {
  final String message;
  const GoalProgressReportError(this.message);
  @override
  List<Object?> get props => [message];
}
