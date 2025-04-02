part of 'summary_bloc.dart'; // Link to the bloc file

abstract class SummaryState extends Equatable {
  const SummaryState();

  @override
  List<Object?> get props => [];
}

// Initial state before anything is loaded
class SummaryInitial extends SummaryState {}

// State indicating that the summary data is being fetched
class SummaryLoading extends SummaryState {}

// State indicating that the summary data has been successfully loaded
class SummaryLoaded extends SummaryState {
  final ExpenseSummary summary; // Holds the calculated summary data

  const SummaryLoaded(this.summary);

  @override
  List<Object?> get props =>
      [summary]; // Include summary in props for comparison
}

// State indicating an error occurred while fetching the summary
class SummaryError extends SummaryState {
  final String message; // Holds the error message

  const SummaryError(this.message);

  @override
  List<Object> get props => [message]; // Include message in props
}
