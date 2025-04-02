part of 'expense_list_bloc.dart'; // Link to bloc file

abstract class ExpenseListEvent extends Equatable {
  const ExpenseListEvent();

  @override
  List<Object?> get props => [];
}

// Event to load initial or all expenses
class LoadExpenses extends ExpenseListEvent {
  // Optional: carry initial filters if needed
}

// Event to apply filters
class FilterExpenses extends ExpenseListEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category; // Using category name string

  const FilterExpenses({this.startDate, this.endDate, this.category});

  @override
  List<Object?> get props => [startDate, endDate, category];
}

// Event to trigger deletion
class DeleteExpenseRequested extends ExpenseListEvent {
  final String expenseId;
  const DeleteExpenseRequested(this.expenseId);

  @override
  List<Object> get props => [expenseId];
}
