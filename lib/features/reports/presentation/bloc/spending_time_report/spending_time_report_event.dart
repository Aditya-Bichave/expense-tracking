// lib/features/reports/presentation/bloc/spending_time_report/spending_time_report_event.dart
part of 'spending_time_report_bloc.dart';

abstract class SpendingTimeReportEvent extends Equatable {
  const SpendingTimeReportEvent();
  @override
  List<Object?> get props => [];
}

class LoadSpendingTimeReport extends SpendingTimeReportEvent {
  final TimeSeriesGranularity? granularity;
  // --- ADDED compareToPrevious flag ---
  final bool compareToPrevious;
  const LoadSpendingTimeReport({
    this.granularity,
    this.compareToPrevious = false,
  });
  @override
  List<Object?> get props => [granularity, compareToPrevious];
  // --- END ADD ---
}

class ChangeGranularity extends SpendingTimeReportEvent {
  final TimeSeriesGranularity granularity;
  const ChangeGranularity(this.granularity);
  @override
  List<Object?> get props => [granularity];
}

// --- ADDED Toggle Event ---
class ToggleTimeComparison extends SpendingTimeReportEvent {
  const ToggleTimeComparison();
}
// --- END ADD ---

// Internal event for filter changes
class _FilterChanged extends SpendingTimeReportEvent {
  const _FilterChanged();
}
