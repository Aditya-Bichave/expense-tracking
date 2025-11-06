// lib/features/reports/presentation/bloc/report_filter/report_filter_state.dart
part of 'report_filter_bloc.dart';

enum FilterOptionsStatus { initial, loading, loaded, error }

class ReportFilterState extends Equatable {
  // Status for loading options (categories/accounts/budgets/goals)
  final FilterOptionsStatus optionsStatus;
  final String? optionsError;
  final List<Category> availableCategories;
  final List<AssetAccount> availableAccounts;
  final List<Liability> availableLiabilities;
  // --- ADDED ---
  final List<Budget> availableBudgets;
  final List<Goal> availableGoals;
  // --- END ADDED ---

  // Current filter values
  final DateTime startDate; // Non-nullable, default to start of month
  final DateTime endDate; // Non-nullable, default to end of month
  final List<String> selectedCategoryIds;
  final List<String> selectedAccountIds;
  // --- ADDED ---
  final List<String> selectedBudgetIds;
  final List<String> selectedGoalIds;
  final TransactionType? selectedTransactionType;
  // --- END ADDED ---

  const ReportFilterState({
    required this.optionsStatus,
    this.optionsError,
    required this.availableCategories,
    required this.availableAccounts,
    required this.availableLiabilities,
    required this.availableBudgets, // Added
    required this.availableGoals, // Added
    required this.startDate,
    required this.endDate,
    required this.selectedCategoryIds,
    required this.selectedAccountIds,
    required this.selectedBudgetIds, // Added
    required this.selectedGoalIds, // Added
    this.selectedTransactionType, // Added
  });

  // Initial state factory
  factory ReportFilterState.initial() {
    final now = DateTime.now();
    return ReportFilterState(
      optionsStatus: FilterOptionsStatus.initial,
      availableCategories: const [],
      availableAccounts: const [],
      availableLiabilities: const [],
      availableBudgets: const [], // Added
      availableGoals: const [], // Added
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      selectedCategoryIds: const [],
      selectedAccountIds: const [],
      selectedBudgetIds: const [], // Added
      selectedGoalIds: const [], // Added
      selectedTransactionType: null, // Added
    );
  }

  ReportFilterState copyWith({
    FilterOptionsStatus? optionsStatus,
    String? optionsError,
    List<Category>? availableCategories,
    List<AssetAccount>? availableAccounts,
    List<Liability>? availableLiabilities,
    List<Budget>? availableBudgets, // Added
    List<Goal>? availableGoals, // Added
    DateTime? startDate,
    DateTime? endDate,
    List<String>? selectedCategoryIds,
    List<String>? selectedAccountIds,
    List<String>? selectedBudgetIds, // Added
    List<String>? selectedGoalIds, // Added
    TransactionType? selectedTransactionType, // Added
    // Flags
    bool clearDates = false,
    bool clearOptionsError = false,
    // --- ADDED Clear Flags ---
    ValueGetter<TransactionType?>?
        selectedTransactionTypeOrNull, // For clearing
    // --- END ADDED ---
  }) {
    final now = DateTime.now();
    final defaultStart = DateTime(now.year, now.month, 1);
    final defaultEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return ReportFilterState(
      optionsStatus: optionsStatus ?? this.optionsStatus,
      optionsError:
          clearOptionsError ? null : optionsError ?? this.optionsError,
      availableCategories: availableCategories ?? this.availableCategories,
      availableAccounts: availableAccounts ?? this.availableAccounts,
      availableLiabilities: availableLiabilities ?? this.availableLiabilities,
      availableBudgets: availableBudgets ?? this.availableBudgets, // Added
      availableGoals: availableGoals ?? this.availableGoals, // Added
      startDate: clearDates ? defaultStart : (startDate ?? this.startDate),
      endDate: clearDates ? defaultEnd : (endDate ?? this.endDate),
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      selectedAccountIds: selectedAccountIds ?? this.selectedAccountIds,
      selectedBudgetIds: selectedBudgetIds ?? this.selectedBudgetIds, // Added
      selectedGoalIds: selectedGoalIds ?? this.selectedGoalIds, // Added
      // --- UPDATED ---
      selectedTransactionType: selectedTransactionTypeOrNull != null
          ? selectedTransactionTypeOrNull() // Use getter to allow null
          : (selectedTransactionType ?? this.selectedTransactionType),
      // --- END UPDATED ---
    );
  }

  @override
  List<Object?> get props => [
        optionsStatus, optionsError, availableCategories, availableAccounts,
        availableLiabilities,
        availableBudgets, availableGoals, // Added
        startDate, endDate, selectedCategoryIds, selectedAccountIds,
        selectedBudgetIds, selectedGoalIds, selectedTransactionType, // Added
      ];
}
