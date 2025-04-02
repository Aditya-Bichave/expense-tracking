part of 'income_list_bloc.dart';

abstract class IncomeListState extends Equatable {
  const IncomeListState();
  @override
  List<Object?> get props => [];
}

class IncomeListInitial extends IncomeListState {}

class IncomeListLoading extends IncomeListState {
  final bool
      isReloading; // True if loading triggered while data was already loaded
  const IncomeListLoading({this.isReloading = false});

  @override
  List<Object> get props => [isReloading];
}

class IncomeListLoaded extends IncomeListState {
  final List<Income> incomes;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String? filterCategory;
  final String? filterAccountId;

  const IncomeListLoaded({
    required this.incomes,
    this.filterStartDate,
    this.filterEndDate,
    this.filterCategory,
    this.filterAccountId,
  });

  @override
  List<Object?> get props => [
        incomes,
        filterStartDate,
        filterEndDate,
        filterCategory,
        filterAccountId,
      ];
}

class IncomeListError extends IncomeListState {
  final String message;
  const IncomeListError(this.message);
  @override
  List<Object> get props => [message];
}
