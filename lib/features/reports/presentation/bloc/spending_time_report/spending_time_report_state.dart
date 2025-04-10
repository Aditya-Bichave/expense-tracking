// lib/features/reports/presentation/bloc/spending_time_report/spending_time_report_state.dart
part of 'spending_time_report_bloc.dart';

abstract class SpendingTimeReportState extends Equatable {
  const SpendingTimeReportState();
  @override
  List<Object?> get props => [];
}

class SpendingTimeReportInitial extends SpendingTimeReportState {}

class SpendingTimeReportLoading extends SpendingTimeReportState {
  final TimeSeriesGranularity granularity; // Track granularity during load
  const SpendingTimeReportLoading({required this.granularity});
  @override
  List<Object?> get props => [granularity];
}

class SpendingTimeReportLoaded extends SpendingTimeReportState {
  final SpendingTimeReportData reportData;
  const SpendingTimeReportLoaded(this.reportData);
  @override
  List<Object?> get props => [reportData];
}

class SpendingTimeReportError extends SpendingTimeReportState {
  final String message;
  const SpendingTimeReportError(this.message);
  @override
  List<Object?> get props => [message];
}
