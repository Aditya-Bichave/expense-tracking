part of 'recurring_list_bloc.dart';

abstract class RecurringListState extends Equatable {
  const RecurringListState();

  @override
  List<Object> get props => [];
}

class RecurringListInitial extends RecurringListState {}

class RecurringListLoading extends RecurringListState {}

class RecurringListLoaded extends RecurringListState {
  final List<RecurringRule> rules;

  const RecurringListLoaded(this.rules);

  @override
  List<Object> get props => [rules];
}

class RecurringListError extends RecurringListState {
  final String message;

  const RecurringListError(this.message);

  @override
  List<Object> get props => [message];
}
