// lib/features/reports/presentation/bloc/spending_time_report/spending_time_report_state.dart
part of 'spending_time_report_bloc.dart';

abstract class SpendingTimeReportState extends Equatable {
  const SpendingTimeReportState();
  @override
  List<Object?> get props => [];
}

class SpendingTimeReportInitial extends SpendingTimeReportState {}

class SpendingTimeReportLoading extends SpendingTimeReportState {
  final TimeSeriesGranularity granularity;
  // --- ADDED compareToPrevious flag ---
  final bool compareToPrevious;
  const SpendingTimeReportLoading({
    required this.granularity,
    required this.compareToPrevious,
  });
  @override
  List<Object?> get props => [granularity, compareToPrevious];
  // --- END ADD ---
}

class SpendingTimeReportLoaded extends SpendingTimeReportState {
  final SpendingTimeReportData reportData;
  // --- ADDED showComparison flag ---
  final bool showComparison;
  const SpendingTimeReportLoaded(
    this.reportData, {
    required this.showComparison,
  });
  @override
  List<Object?> get props => [reportData, showComparison];
  // --- END ADD ---
}

class SpendingTimeReportError extends SpendingTimeReportState {
  final String message;
  const SpendingTimeReportError(this.message);
  @override
  List<Object?> get props => [message];
}
