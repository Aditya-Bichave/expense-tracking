// lib/features/reports/presentation/bloc/spending_time_report/spending_time_report_event.dart
part of 'spending_time_report_bloc.dart';

abstract class SpendingTimeReportEvent extends Equatable {
  const SpendingTimeReportEvent();
  @override
  List<Object?> get props => [];
}

// Trigger load/reload, optionally specifying granularity
class LoadSpendingTimeReport extends SpendingTimeReportEvent {
  final TimeSeriesGranularity? granularity;
  const LoadSpendingTimeReport({this.granularity});
  @override
  List<Object?> get props => [granularity];
}

// Change granularity and trigger reload
class ChangeGranularity extends SpendingTimeReportEvent {
  final TimeSeriesGranularity granularity;
  const ChangeGranularity(this.granularity);
  @override
  List<Object?> get props => [granularity];
}

// Internal event for filter changes
class _FilterChanged extends SpendingTimeReportEvent {
  const _FilterChanged();
}
