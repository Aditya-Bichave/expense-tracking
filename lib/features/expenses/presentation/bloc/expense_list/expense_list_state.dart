part of 'expense_list_bloc.dart';

abstract class ExpenseListState extends Equatable {
  const ExpenseListState();

  @override
  List<Object?> get props => [];
}

class ExpenseListInitial extends ExpenseListState {}

class ExpenseListLoading extends ExpenseListState {
  final bool
      isReloading; // True if loading triggered while data was already loaded
  const ExpenseListLoading({this.isReloading = false});

  @override
  List<Object> get props => [isReloading];
}

class ExpenseListLoaded extends ExpenseListState {
  final List<Expense> expenses;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String? filterCategory;
  final String? filterAccountId; // Include account filter in state

  const ExpenseListLoaded({
    required this.expenses,
    this.filterStartDate,
    this.filterEndDate,
    this.filterCategory,
    this.filterAccountId,
  });

  @override
  List<Object?> get props => [
        expenses,
        filterStartDate,
        filterEndDate,
        filterCategory,
        filterAccountId // Add to props
      ];
}

class ExpenseListError extends ExpenseListState {
  final String message;
  const ExpenseListError(this.message);

  @override
  List<Object> get props => [message];
}
