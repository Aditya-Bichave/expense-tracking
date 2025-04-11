// lib/features/reports/presentation/bloc/income_expense_report/income_expense_report_state.dart
part of 'income_expense_report_bloc.dart';

abstract class IncomeExpenseReportState extends Equatable {
  const IncomeExpenseReportState();
  @override
  List<Object?> get props => [];
}

class IncomeExpenseReportInitial extends IncomeExpenseReportState {}

class IncomeExpenseReportLoading extends IncomeExpenseReportState {
  final IncomeExpensePeriodType periodType;
  // --- ADDED compareToPrevious flag ---
  final bool compareToPrevious;
  const IncomeExpenseReportLoading(
      {required this.periodType, required this.compareToPrevious});
  @override
  List<Object?> get props => [periodType, compareToPrevious];
  // --- END ADD ---
}

class IncomeExpenseReportLoaded extends IncomeExpenseReportState {
  final IncomeExpenseReportData reportData;
  // --- ADDED showComparison flag ---
  final bool showComparison;
  const IncomeExpenseReportLoaded(this.reportData,
      {required this.showComparison});
  @override
  List<Object?> get props => [reportData, showComparison];
  // --- END ADD ---
}

class IncomeExpenseReportError extends IncomeExpenseReportState {
  final String message;
  const IncomeExpenseReportError(this.message);
  @override
  List<Object?> get props => [message];
}
