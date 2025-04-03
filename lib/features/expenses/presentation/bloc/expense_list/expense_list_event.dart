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
  final String? category; // Using category name string (might change to ID)
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

// --- Batch Edit Events ---
class ToggleBatchEditMode extends ExpenseListEvent {
  const ToggleBatchEditMode();
}

class SelectExpense extends ExpenseListEvent {
  final String expenseId;
  const SelectExpense(this.expenseId);
  @override
  List<Object> get props => [expenseId];
}

class ApplyBatchCategory extends ExpenseListEvent {
  final String categoryId; // ID of the category to apply
  const ApplyBatchCategory(this.categoryId);
  @override
  List<Object> get props => [categoryId];
}
// --- END Batch Edit Events ---

// --- Single Update Event (for categorization status/id) ---
class UpdateSingleExpenseCategory extends ExpenseListEvent {
  final String expenseId;
  final String? categoryId; // Can be null to uncategorize
  final CategorizationStatus status;
  final double? confidence;

  const UpdateSingleExpenseCategory({
    required this.expenseId,
    required this.categoryId,
    required this.status,
    this.confidence,
  });

  @override
  List<Object?> get props => [expenseId, categoryId, status, confidence];
}
// --- END Single Update Event ---

// --- Event when user explicitly sets/confirms a category ---
class UserCategorizedExpense extends ExpenseListEvent {
  final String expenseId;
  final Category selectedCategory; // Use unified Category
  final TransactionMatchData matchData; // Data used for learning rule

  const UserCategorizedExpense({
    required this.expenseId,
    required this.selectedCategory,
    required this.matchData,
  });

  @override
  List<Object?> get props => [expenseId, selectedCategory, matchData];
}
// --- END ADDED ---

// Internal event for data changes
class _DataChanged extends ExpenseListEvent {
  const _DataChanged();
}
