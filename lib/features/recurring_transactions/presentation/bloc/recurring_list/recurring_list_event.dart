part of 'recurring_list_bloc.dart';

abstract class RecurringListEvent extends Equatable {
  const RecurringListEvent();

  @override
  List<Object> get props => [];
}

class LoadRecurringRules extends RecurringListEvent {}

class PauseResumeRule extends RecurringListEvent {
  final String ruleId;
  const PauseResumeRule(this.ruleId);
}

class DeleteRule extends RecurringListEvent {
  final String ruleId;
  const DeleteRule(this.ruleId);
}

class ResetState extends RecurringListEvent {
  const ResetState();
}
