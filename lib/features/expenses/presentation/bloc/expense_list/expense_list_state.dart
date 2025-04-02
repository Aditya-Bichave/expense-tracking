part of 'expense_list_bloc.dart'; // Link to bloc file

abstract class ExpenseListState extends Equatable {
  const ExpenseListState();

  @override
  List<Object?> get props => [];
}

class ExpenseListInitial extends ExpenseListState {}

class ExpenseListLoading extends ExpenseListState {}

class ExpenseListLoaded extends ExpenseListState {
  final List<Expense> expenses;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String? filterCategory;

  const ExpenseListLoaded({
    required this.expenses,
    this.filterStartDate,
    this.filterEndDate,
    this.filterCategory,
  });

  @override
  List<Object?> get props =>
      [expenses, filterStartDate, filterEndDate, filterCategory];
}

class ExpenseListError extends ExpenseListState {
  final String message;
  const ExpenseListError(this.message);

  @override
  List<Object> get props => [message];
}
