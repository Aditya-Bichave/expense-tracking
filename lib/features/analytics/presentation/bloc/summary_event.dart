part of 'summary_bloc.dart';

abstract class SummaryEvent extends Equatable {
  const SummaryEvent();

  @override
  List<Object?> get props => [];
}

// Event triggered to load/refresh the expense summary, optionally updating filters
class LoadSummary extends SummaryEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool forceReload;
  final bool
  updateFilters; // Flag to indicate if these dates should become the new stored filters

  const LoadSummary({
    this.startDate,
    this.endDate,
    this.forceReload = false,
    this.updateFilters =
        true, // Default to true when manually loading/filtering
  });

  @override
  List<Object?> get props => [startDate, endDate, forceReload, updateFilters];
}

// Internal event triggered by stream listener (doesn't update filters)
class _DataChanged extends SummaryEvent {
  const _DataChanged();
}

// --- ADDED: Reset State Event ---
class ResetState extends SummaryEvent {
  const ResetState();
}

// --- END ADDED ---
