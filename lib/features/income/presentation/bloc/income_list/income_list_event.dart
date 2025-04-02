part of 'income_list_bloc.dart';

abstract class IncomeListEvent extends Equatable {
  const IncomeListEvent();
  @override
  List<Object?> get props => [];
}

class LoadIncomes extends IncomeListEvent {
  final bool forceReload;
  const LoadIncomes({this.forceReload = false});

  @override
  List<Object?> get props => [forceReload];
}

class FilterIncomes extends IncomeListEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  final String? accountId;

  const FilterIncomes(
      {this.startDate, this.endDate, this.category, this.accountId});

  @override
  List<Object?> get props => [startDate, endDate, category, accountId];
}

class DeleteIncomeRequested extends IncomeListEvent {
  final String incomeId;
  const DeleteIncomeRequested(this.incomeId);
  @override
  List<Object> get props => [incomeId];
}

// Internal event
class _DataChanged extends IncomeListEvent {
  const _DataChanged();
}
