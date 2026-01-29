part of 'summary_bloc.dart';

abstract class SummaryState extends Equatable {
  const SummaryState();

  @override
  List<Object?> get props => [];
}

class SummaryInitial extends SummaryState {}

class SummaryLoading extends SummaryState {
  final bool
      isReloading; // True if loading triggered while data was already loaded
  final ExpenseSummary? previousSummary;

  const SummaryLoading({this.isReloading = false, this.previousSummary});

  @override
  List<Object?> get props => [isReloading, previousSummary];
}

class SummaryLoaded extends SummaryState {
  final ExpenseSummary summary;

  const SummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class SummaryError extends SummaryState {
  final String message;

  const SummaryError(this.message);

  @override
  List<Object> get props => [message];
}
