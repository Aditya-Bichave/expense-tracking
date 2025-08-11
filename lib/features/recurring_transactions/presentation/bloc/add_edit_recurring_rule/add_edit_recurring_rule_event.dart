part of 'add_edit_recurring_rule_bloc.dart';

abstract class AddEditRecurringRuleEvent extends Equatable {
  const AddEditRecurringRuleEvent();

  @override
  List<Object?> get props => [];
}

class InitializeForEdit extends AddEditRecurringRuleEvent {
  final RecurringRule rule;
  const InitializeForEdit(this.rule);
}

class DescriptionChanged extends AddEditRecurringRuleEvent {
  final String description;
  const DescriptionChanged(this.description);
}

class AmountChanged extends AddEditRecurringRuleEvent {
  final String amount;
  const AmountChanged(this.amount);
}

class TransactionTypeChanged extends AddEditRecurringRuleEvent {
  final TransactionType transactionType;
  const TransactionTypeChanged(this.transactionType);
}

class AccountChanged extends AddEditRecurringRuleEvent {
  final String? accountId;
  const AccountChanged(this.accountId);
}

class CategoryChanged extends AddEditRecurringRuleEvent {
  final Category category;
  const CategoryChanged(this.category);
}

class FrequencyChanged extends AddEditRecurringRuleEvent {
  final Frequency frequency;
  const FrequencyChanged(this.frequency);
}

class IntervalChanged extends AddEditRecurringRuleEvent {
  final String interval;
  const IntervalChanged(this.interval);
}

class StartDateChanged extends AddEditRecurringRuleEvent {
  final DateTime startDate;
  const StartDateChanged(this.startDate);
}

class EndConditionTypeChanged extends AddEditRecurringRuleEvent {
  final EndConditionType endConditionType;
  const EndConditionTypeChanged(this.endConditionType);
}

class EndDateChanged extends AddEditRecurringRuleEvent {
  final DateTime endDate;
  const EndDateChanged(this.endDate);
}

class TotalOccurrencesChanged extends AddEditRecurringRuleEvent {
  final String occurrences;
  const TotalOccurrencesChanged(this.occurrences);
}

class DayOfWeekChanged extends AddEditRecurringRuleEvent {
  final int dayOfWeek;
  const DayOfWeekChanged(this.dayOfWeek);
}

class DayOfMonthChanged extends AddEditRecurringRuleEvent {
  final int dayOfMonth;
  const DayOfMonthChanged(this.dayOfMonth);
}

class TimeChanged extends AddEditRecurringRuleEvent {
  final TimeOfDay time;
  const TimeChanged(this.time);
}

class FormSubmitted extends AddEditRecurringRuleEvent {}
