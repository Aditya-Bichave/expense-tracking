// lib/features/reports/presentation/bloc/spending_category_report/spending_category_report_event.dart
part of 'spending_category_report_bloc.dart';

abstract class SpendingCategoryReportEvent extends Equatable {
  const SpendingCategoryReportEvent();
  @override
  List<Object?> get props => [];
}

class LoadSpendingCategoryReport extends SpendingCategoryReportEvent {
  // --- ADDED compareToPrevious flag ---
  final bool compareToPrevious;
  const LoadSpendingCategoryReport({this.compareToPrevious = false});
  @override
  List<Object?> get props => [compareToPrevious];
  // --- END ADD ---
}

// --- ADDED Toggle Event ---
class ToggleSpendingComparison extends SpendingCategoryReportEvent {
  const ToggleSpendingComparison();
}
// --- END ADD ---

// Internal event triggered by filter changes
class _FilterChanged extends SpendingCategoryReportEvent {
  const _FilterChanged();
}
