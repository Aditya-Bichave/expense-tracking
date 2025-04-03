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
  final List<Expense>
      items; // The list of expenses (now includes hydrated category)
  @override
  final DateTime? filterStartDate;
  @override
  final DateTime? filterEndDate;
  @override
  final String? filterCategory; // Filter name (may need adjustment)
  @override
  final String? filterAccountId;

  // --- ADDED Batch Edit State ---
  final bool isInBatchEditMode;
  final Set<String> selectedTransactionIds;
  // --- END ADDED ---

  const ExpenseListLoaded({
    required List<Expense> expenses, // Renamed parameter for clarity
    this.filterStartDate,
    this.filterEndDate,
    this.filterCategory,
    this.filterAccountId,
    this.isInBatchEditMode = false, // Default to false
    this.selectedTransactionIds = const {}, // Default to empty set
  })  : items = expenses, // Assign to base 'items'
        super();

  @override
  bool get filtersApplied =>
      filterStartDate != null ||
      filterEndDate != null ||
      filterCategory != null ||
      filterAccountId != null;

  // Convenience getter
  List<Expense> get expenses => items;

  // --- ADDED copyWith method ---
  ExpenseListLoaded copyWith({
    List<Expense>? expenses,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    String? filterCategory,
    String? filterAccountId,
    bool? isInBatchEditMode,
    Set<String>? selectedTransactionIds,
    // Flags to explicitly clear nullable fields if needed
    bool clearFilterCategory = false,
    bool clearFilterAccountId = false,
    bool clearFilterStartDate = false,
    bool clearFilterEndDate = false,
  }) {
    return ExpenseListLoaded(
      expenses: expenses ?? this.items, // Use items here
      filterStartDate: clearFilterStartDate
          ? null
          : (filterStartDate ?? this.filterStartDate),
      filterEndDate:
          clearFilterEndDate ? null : (filterEndDate ?? this.filterEndDate),
      filterCategory:
          clearFilterCategory ? null : (filterCategory ?? this.filterCategory),
      filterAccountId: clearFilterAccountId
          ? null
          : (filterAccountId ?? this.filterAccountId),
      isInBatchEditMode: isInBatchEditMode ?? this.isInBatchEditMode,
      selectedTransactionIds:
          selectedTransactionIds ?? this.selectedTransactionIds,
    );
  }
  // --- END ADDED ---

  @override
  List<Object?> get props => [
        items, // Use items here for Equatable comparison
        filterStartDate,
        filterEndDate,
        filterCategory,
        filterAccountId,
        isInBatchEditMode, // Added
        selectedTransactionIds, // Added
      ];
}

// Extend base error state
class ExpenseListError extends ExpenseListState implements BaseListErrorState {
  @override
  final String message;
  const ExpenseListError(this.message);

  @override
  List<Object> get props => [message];
}
