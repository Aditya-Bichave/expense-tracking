// lib/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_state.dart
part of 'budget_performance_report_bloc.dart';

abstract class BudgetPerformanceReportState extends Equatable {
  const BudgetPerformanceReportState();
  @override
  List<Object?> get props => [];
}

class BudgetPerformanceReportInitial extends BudgetPerformanceReportState {}

class BudgetPerformanceReportLoading extends BudgetPerformanceReportState {
  final bool compareToPrevious; // Track if comparison is being loaded
  const BudgetPerformanceReportLoading({required this.compareToPrevious});
  @override
  List<Object?> get props => [compareToPrevious];
}

class BudgetPerformanceReportLoaded extends BudgetPerformanceReportState {
  final BudgetPerformanceReportData reportData;
  final bool showComparison; // Whether comparison data should be shown in UI
  const BudgetPerformanceReportLoaded(
    this.reportData, {
    required this.showComparison,
  });
  @override
  List<Object?> get props => [reportData, showComparison];
}

class BudgetPerformanceReportError extends BudgetPerformanceReportState {
  final String message;
  const BudgetPerformanceReportError(this.message);
  @override
  List<Object?> get props => [message];
}
