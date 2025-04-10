// lib/features/reports/presentation/bloc/income_expense_report/income_expense_report_state.dart
part of 'income_expense_report_bloc.dart';

abstract class IncomeExpenseReportState extends Equatable {
  const IncomeExpenseReportState();
  @override
  List<Object?> get props => [];
}

class IncomeExpenseReportInitial extends IncomeExpenseReportState {}

class IncomeExpenseReportLoading extends IncomeExpenseReportState {
  final IncomeExpensePeriodType periodType; // Track period during load
  const IncomeExpenseReportLoading({required this.periodType});
  @override
  List<Object?> get props => [periodType];
}

class IncomeExpenseReportLoaded extends IncomeExpenseReportState {
  final IncomeExpenseReportData reportData;
  const IncomeExpenseReportLoaded(this.reportData);
  @override
  List<Object?> get props => [reportData];
}

class IncomeExpenseReportError extends IncomeExpenseReportState {
  final String message;
  const IncomeExpenseReportError(this.message);
  @override
  List<Object?> get props => [message];
}
