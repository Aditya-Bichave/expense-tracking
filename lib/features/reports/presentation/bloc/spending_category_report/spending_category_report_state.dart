// lib/features/reports/presentation/bloc/spending_category_report/spending_category_report_state.dart
part of 'spending_category_report_bloc.dart';

abstract class SpendingCategoryReportState extends Equatable {
  const SpendingCategoryReportState();
  @override
  List<Object?> get props => [];
}

class SpendingCategoryReportInitial extends SpendingCategoryReportState {}

class SpendingCategoryReportLoading extends SpendingCategoryReportState {}

class SpendingCategoryReportLoaded extends SpendingCategoryReportState {
  final SpendingCategoryReportData reportData;
  const SpendingCategoryReportLoaded(this.reportData);
  @override
  List<Object?> get props => [reportData];
}

class SpendingCategoryReportError extends SpendingCategoryReportState {
  final String message;
  const SpendingCategoryReportError(this.message);
  @override
  List<Object?> get props => [message];
}
