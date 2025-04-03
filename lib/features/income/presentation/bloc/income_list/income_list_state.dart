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
  final List<Income>
      items; // The list of incomes (now includes hydrated category)
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

  const IncomeListLoaded({
    required List<Income> incomes, // Renamed parameter for clarity
    this.filterStartDate,
    this.filterEndDate,
    this.filterCategory,
    this.filterAccountId,
    this.isInBatchEditMode = false, // Default to false
    this.selectedTransactionIds = const {}, // Default to empty set
  })  : items = incomes, // Assign to base 'items'
        super();

  @override
  bool get filtersApplied =>
      filterStartDate != null ||
      filterEndDate != null ||
      filterCategory != null ||
      filterAccountId != null;

  // Convenience getter
  List<Income> get incomes => items;

  // --- ADDED copyWith method ---
  IncomeListLoaded copyWith({
    List<Income>? incomes,
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
    return IncomeListLoaded(
      incomes: incomes ?? this.items, // Use items here
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
class IncomeListError extends IncomeListState implements BaseListErrorState {
  @override
  final String message;
  const IncomeListError(this.message);

  @override
  List<Object> get props => [message];
}
