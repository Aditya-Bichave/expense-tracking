// lib/features/reports/presentation/bloc/spending_category_report/spending_category_report_event.dart
part of 'spending_category_report_bloc.dart';

abstract class SpendingCategoryReportEvent extends Equatable {
  const SpendingCategoryReportEvent();
  @override
  List<Object?> get props => [];
}

// Event to trigger loading/reloading the report
class LoadSpendingCategoryReport extends SpendingCategoryReportEvent {
  const LoadSpendingCategoryReport();
}

// Internal event triggered by filter changes
class _FilterChanged extends SpendingCategoryReportEvent {
  const _FilterChanged();
}
