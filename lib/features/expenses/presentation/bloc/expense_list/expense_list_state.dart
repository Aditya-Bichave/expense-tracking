// lib/features/expenses/presentation/bloc/expense_list/expense_list_state.dart
part of 'expense_list_bloc.dart';

// Base state for this feature
abstract class ExpenseListState extends Equatable {
  const ExpenseListState();

  @override
  List<Object?> get props => [];
}

// Extend base initial state
class ExpenseListInitial extends ExpenseListState
    implements BaseListInitialState {
  const ExpenseListInitial();
}

// Extend base loading state
class ExpenseListLoading extends ExpenseListState
    implements BaseListLoadingState {
  @override
  final bool isReloading;
  const ExpenseListLoading({this.isReloading = false});

  @override
  List<Object> get props => [isReloading];
}

// Extend BaseListState<Expense>
class ExpenseListLoaded extends ExpenseListState
    implements BaseListState<Expense> {
  @override
  final List<Expense> items; // The list of expenses
  @override
  final DateTime? filterStartDate;
  @override
  final DateTime? filterEndDate;
  @override
  final String? filterCategory;
  @override
  final String? filterAccountId;

  const ExpenseListLoaded({
    required List<Expense> expenses,
    this.filterStartDate,
    this.filterEndDate,
    this.filterCategory,
    this.filterAccountId,
  })  : items = expenses,
        super();

  // --- ADDED: Concrete implementation for filtersApplied ---
  @override
  bool get filtersApplied =>
      filterStartDate != null ||
      filterEndDate != null ||
      filterCategory != null ||
      filterAccountId != null;
  // ---------------------------------------------------------

  // Props are handled by the base class via its getter
  @override
  List<Object?> get props => [
        // Need to explicitly list props here now
        items,
        filterStartDate,
        filterEndDate,
        filterCategory,
        filterAccountId,
      ];

  // Convenience getter (optional)
  List<Expense> get expenses => items;
}

// Extend base error state
class ExpenseListError extends ExpenseListState implements BaseListErrorState {
  @override
  final String message;
  const ExpenseListError(this.message);

  @override
  List<Object> get props => [message];
}
