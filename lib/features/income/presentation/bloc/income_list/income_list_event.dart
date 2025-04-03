part of 'income_list_bloc.dart';

abstract class IncomeListEvent extends Equatable {
  const IncomeListEvent();
  @override
  List<Object?> get props => [];
}

class LoadIncomes extends IncomeListEvent {
  final bool forceReload;
  const LoadIncomes({this.forceReload = false});

  @override
  List<Object?> get props => [forceReload];
}

class FilterIncomes extends IncomeListEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  final String? accountId;

  const FilterIncomes(
      {this.startDate, this.endDate, this.category, this.accountId});

  @override
  List<Object?> get props => [startDate, endDate, category, accountId];
}

class DeleteIncomeRequested extends IncomeListEvent {
  final String incomeId;
  const DeleteIncomeRequested(this.incomeId);
  @override
  List<Object> get props => [incomeId];
}

// --- Batch Edit Events ---
class ToggleBatchEditMode extends IncomeListEvent {
  const ToggleBatchEditMode();
}

class SelectIncome extends IncomeListEvent {
  final String incomeId;
  const SelectIncome(this.incomeId);
  @override
  List<Object> get props => [incomeId];
}

class ApplyBatchCategory extends IncomeListEvent {
  final String categoryId; // ID of the category to apply
  const ApplyBatchCategory(this.categoryId);
  @override
  List<Object> get props => [categoryId];
}
// --- END Batch Edit Events ---

// --- Single Update Event ---
class UpdateSingleIncomeCategory extends IncomeListEvent {
  final String incomeId;
  final String? categoryId; // Can be null to uncategorize
  final CategorizationStatus status;
  final double? confidence;

  const UpdateSingleIncomeCategory({
    required this.incomeId,
    required this.categoryId,
    required this.status,
    this.confidence,
  });

  @override
  List<Object?> get props => [incomeId, categoryId, status, confidence];
}
// --- END Single Update Event ---

// --- Event when user explicitly sets/confirms a category ---
class UserCategorizedIncome extends IncomeListEvent {
  final String incomeId;
  final Category selectedCategory; // Use unified Category
  final TransactionMatchData matchData; // Data used for learning rule

  const UserCategorizedIncome({
    required this.incomeId,
    required this.selectedCategory,
    required this.matchData,
  });

  @override
  List<Object?> get props => [incomeId, selectedCategory, matchData];
}
// --- END ADDED ---

// Internal event for data changes
class _DataChanged extends IncomeListEvent {
  const _DataChanged();
}
