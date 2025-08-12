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
  const AccountListLoading({this.isReloading = false});

  @override
  List<Object> get props => [isReloading];
}

// Extend BaseListState<AssetAccount>
class AccountListLoaded extends AccountListState
    implements BaseListState<AssetAccount> {
  @override
  final List<AssetAccount> items; // The list of accounts
  final String? errorMessage;

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
    required List<AssetAccount> accounts,
    this.errorMessage,
  }) : items = accounts;

  @override
  bool get filtersApplied =>
      filterStartDate != null ||
      filterEndDate != null ||
      filterCategory != null ||
      filterAccountId != null;

  @override
  List<Object?> get props => [
        items,
        errorMessage,
        filterStartDate,
        filterEndDate,
        filterCategory,
        filterAccountId,
      ];

  // Convenience getter (optional)
  List<AssetAccount> get accounts => items;

  AccountListLoaded copyWith({
    List<AssetAccount>? accounts,
    String? errorMessage,
    bool? clearErrorMessage,
  }) {
    return AccountListLoaded(
      accounts: accounts ?? this.items,
      errorMessage: clearErrorMessage == true ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// Extend base error state
class AccountListError extends AccountListState implements BaseListErrorState {
  @override
  final String message;
  const AccountListError(this.message);

  @override
  List<Object> get props => [message];
}
