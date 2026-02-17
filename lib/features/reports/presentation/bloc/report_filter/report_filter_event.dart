// lib/features/reports/presentation/bloc/report_filter/report_filter_event.dart
part of 'report_filter_bloc.dart';

abstract class ReportFilterEvent extends Equatable {
  const ReportFilterEvent();
  @override
  List<Object?> get props => [];
}

class LoadFilterOptions extends ReportFilterEvent {
  final bool forceReload;
  const LoadFilterOptions({this.forceReload = false});
  @override
  List<Object?> get props => [forceReload];
}

class UpdateReportFilters extends ReportFilterEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? categoryIds;
  final List<String>? accountIds;
  // --- ADDED ---
  final List<String>? budgetIds;
  final List<String>? goalIds;
  final TransactionType? transactionType;
  // --- END ADDED ---

  const UpdateReportFilters({
    this.startDate,
    this.endDate,
    this.categoryIds,
    this.accountIds,
    this.budgetIds, // Added
    this.goalIds, // Added
    this.transactionType, // Added
  });

  @override
  List<Object?> get props => [
    startDate, endDate, categoryIds, accountIds,
    budgetIds, goalIds, transactionType, // Added
  ];
}

class ClearReportFilters extends ReportFilterEvent {
  const ClearReportFilters();
}
