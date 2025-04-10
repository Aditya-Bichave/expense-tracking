// lib/features/reports/presentation/bloc/income_expense_report/income_expense_report_event.dart
part of 'income_expense_report_bloc.dart';

abstract class IncomeExpenseReportEvent extends Equatable {
  const IncomeExpenseReportEvent();
  @override
  List<Object?> get props => [];
}

// Trigger load/reload, optionally specifying period type
class LoadIncomeExpenseReport extends IncomeExpenseReportEvent {
  final IncomeExpensePeriodType? periodType;
  const LoadIncomeExpenseReport({this.periodType});
  @override
  List<Object?> get props => [periodType];
}

// Change period type (monthly/yearly) and trigger reload
class ChangeIncomeExpensePeriod extends IncomeExpenseReportEvent {
  final IncomeExpensePeriodType periodType;
  const ChangeIncomeExpensePeriod(this.periodType);
  @override
  List<Object?> get props => [periodType];
}

// Internal event for filter changes
class _FilterChanged extends IncomeExpenseReportEvent {
  const _FilterChanged();
}
