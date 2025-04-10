// lib/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_event.dart
part of 'budget_performance_report_bloc.dart';

abstract class BudgetPerformanceReportEvent extends Equatable {
  const BudgetPerformanceReportEvent();
  @override
  List<Object?> get props => [];
}

class LoadBudgetPerformanceReport extends BudgetPerformanceReportEvent {
  final bool compareToPrevious; // Flag to control comparison data loading
  const LoadBudgetPerformanceReport({this.compareToPrevious = false});
  @override
  List<Object?> get props => [compareToPrevious];
}

class ToggleBudgetComparison extends BudgetPerformanceReportEvent {
  const ToggleBudgetComparison();
}

// Internal event for filter changes
class _FilterChanged extends BudgetPerformanceReportEvent {
  const _FilterChanged();
}
