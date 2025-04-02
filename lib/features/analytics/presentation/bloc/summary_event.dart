part of 'summary_bloc.dart'; // Link to the bloc file

abstract class SummaryEvent extends Equatable {
  const SummaryEvent();

  @override
  List<Object?> get props => [];
}

// Event triggered to load/refresh the expense summary
class LoadSummary extends SummaryEvent {
  // Optional filters to calculate summary for a specific period
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadSummary({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate]; // Include filters in props
}
