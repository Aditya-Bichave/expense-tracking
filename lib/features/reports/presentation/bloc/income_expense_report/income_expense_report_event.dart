// lib/features/reports/presentation/bloc/income_expense_report/income_expense_report_event.dart
part of 'income_expense_report_bloc.dart';

abstract class IncomeExpenseReportEvent extends Equatable {
  const IncomeExpenseReportEvent();
  @override
  List<Object?> get props => [];
}

class LoadIncomeExpenseReport extends IncomeExpenseReportEvent {
  final IncomeExpensePeriodType? periodType;
  // --- ADDED compareToPrevious flag ---
  final bool compareToPrevious;
  const LoadIncomeExpenseReport({
    this.periodType,
    this.compareToPrevious = false,
  });
  @override
  List<Object?> get props => [periodType, compareToPrevious];
  // --- END ADD ---
}

class ChangeIncomeExpensePeriod extends IncomeExpenseReportEvent {
  final IncomeExpensePeriodType periodType;
  const ChangeIncomeExpensePeriod(this.periodType);
  @override
  List<Object?> get props => [periodType];
}

// --- ADDED Toggle Event ---
class ToggleIncomeExpenseComparison extends IncomeExpenseReportEvent {
  const ToggleIncomeExpenseComparison();
}
// --- END ADD ---

// Internal event for filter changes
class _FilterChanged extends IncomeExpenseReportEvent {
  const _FilterChanged();
}
