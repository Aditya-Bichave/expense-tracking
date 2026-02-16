// lib/features/reports/presentation/bloc/spending_category_report/spending_category_report_state.dart
part of 'spending_category_report_bloc.dart';

abstract class SpendingCategoryReportState extends Equatable {
  const SpendingCategoryReportState();
  @override
  List<Object?> get props => [];
}

class SpendingCategoryReportInitial extends SpendingCategoryReportState {}

class SpendingCategoryReportLoading extends SpendingCategoryReportState {
  // --- ADDED compareToPrevious flag ---
  final bool compareToPrevious;
  const SpendingCategoryReportLoading({required this.compareToPrevious});
  @override
  List<Object?> get props => [compareToPrevious];
  // --- END ADD ---
}

class SpendingCategoryReportLoaded extends SpendingCategoryReportState {
  final SpendingCategoryReportData reportData;
  // --- ADDED showComparison flag ---
  final bool showComparison;
  const SpendingCategoryReportLoaded(
    this.reportData, {
    required this.showComparison,
  });
  @override
  List<Object?> get props => [reportData, showComparison];
  // --- END ADD ---
}

class SpendingCategoryReportError extends SpendingCategoryReportState {
  final String message;
  const SpendingCategoryReportError(this.message);
  @override
  List<Object?> get props => [message];
}
