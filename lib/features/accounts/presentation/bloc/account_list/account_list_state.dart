// lib/features/accounts/presentation/bloc/account_list/account_list_state.dart
part of 'account_list_bloc.dart';

// Base state for this feature
abstract class AccountListState extends Equatable {
  const AccountListState();
  @override
  List<Object?> get props => [];
}

// Extend base initial state
class AccountListInitial extends AccountListState
    implements BaseListInitialState {
  const AccountListInitial();
}

// Extend base loading state
class AccountListLoading extends AccountListState
    implements BaseListLoadingState {
  @override
  final bool isReloading;

  /// Rows already on screen when this reload started.
  ///
  /// The list page keeps showing these while the refresh is in flight so the
  /// list does not blank out mid-pull. It cannot read them back off the bloc:
  /// by the time the builder runs, the bloc's current state *is* this loading
  /// state, so there is no earlier state left to consult.
  final List<AssetAccount> previousItems;

  const AccountListLoading({
    this.isReloading = false,
    this.previousItems = const [],
  });

  @override
  List<Object> get props => [isReloading, previousItems];
}

// Extend BaseListState<AssetAccount>
class AccountListLoaded extends AccountListState
    implements BaseListState<AssetAccount> {
  @override
  final List<AssetAccount> items; // The list of accounts
  // Account list doesn't have filters yet, keep these null
  @override
  final DateTime? filterStartDate = null;
  @override
  final DateTime? filterEndDate = null;
  @override
  final String? filterCategory = null;
  @override
  final String? filterAccountId = null;

  const AccountListLoaded({
    required List<AssetAccount> accounts, // Keep param name
  }) : items = accounts, // Assign to base 'items'
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
  List<AssetAccount> get accounts => items;
}

// Extend base error state
class AccountListError extends AccountListState implements BaseListErrorState {
  @override
  final String message;
  const AccountListError(this.message);

  @override
  List<Object> get props => [message];
}
