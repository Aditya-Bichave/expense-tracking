part of 'expense_list_bloc.dart';

abstract class ExpenseListEvent extends Equatable {
  const ExpenseListEvent();

  @override
  List<Object?> get props => [];
}

// Event to load initial or all expenses
class LoadExpenses extends ExpenseListEvent {
  final bool forceReload;
  const LoadExpenses({this.forceReload = false});

  @override
  List<Object?> get props => [forceReload];
}

// Event to apply filters
class FilterExpenses extends ExpenseListEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category; // Using category name string
  final String? accountId; // Add account filter

  const FilterExpenses(
      {this.startDate, this.endDate, this.category, this.accountId});

  @override
  List<Object?> get props => [startDate, endDate, category, accountId];
}

// Event to trigger deletion
class DeleteExpenseRequested extends ExpenseListEvent {
  final String expenseId;
  const DeleteExpenseRequested(this.expenseId);

  @override
  List<Object> get props => [expenseId];
}

// Internal event for data changes
class _DataChanged extends ExpenseListEvent {
  const _DataChanged();
}
