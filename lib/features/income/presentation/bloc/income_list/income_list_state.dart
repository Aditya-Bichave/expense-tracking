// lib/features/income/presentation/bloc/income_list/income_list_state.dart
part of 'income_list_bloc.dart';

// Base state for this feature
abstract class IncomeListState extends Equatable {
  const IncomeListState();
  @override
  List<Object?> get props => [];
}

// Extend base initial state
class IncomeListInitial extends IncomeListState
    implements BaseListInitialState {
  const IncomeListInitial();
}

// Extend base loading state
class IncomeListLoading extends IncomeListState
    implements BaseListLoadingState {
  @override
  final bool isReloading;
  const IncomeListLoading({this.isReloading = false});

  @override
  List<Object> get props => [isReloading];
}

// Extend BaseListState<Income>
class IncomeListLoaded extends IncomeListState
    implements BaseListState<Income> {
  @override
  final List<Income> items; // The list of incomes
  @override
  final DateTime? filterStartDate;
  @override
  final DateTime? filterEndDate;
  @override
  final String? filterCategory;
  @override
  final String? filterAccountId;

  const IncomeListLoaded({
    required List<Income> incomes, // Keep param name
    this.filterStartDate,
    this.filterEndDate,
    this.filterCategory,
    this.filterAccountId,
  })  : items = incomes, // Assign to base 'items'
        super();

  // --- ADDED: Concrete implementation for filtersApplied ---
  @override
  bool get filtersApplied =>
      filterStartDate != null ||
      filterEndDate != null ||
      filterCategory != null ||
      filterAccountId != null;
  // ---------------------------------------------------------

  // Props handled by base via its getter
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
  List<Income> get incomes => items;
}

// Extend base error state
class IncomeListError extends IncomeListState implements BaseListErrorState {
  @override
  final String message;
  const IncomeListError(this.message);

  @override
  List<Object> get props => [message];
}
