part of 'account_list_bloc.dart';

abstract class AccountListState extends Equatable {
  const AccountListState();
  @override
  List<Object> get props => [];
}

class AccountListInitial extends AccountListState {}

// Combined Loading state, can differentiate based on flag
class AccountListLoading extends AccountListState {
  final bool
      isReloading; // True if loading triggered while data was already loaded
  const AccountListLoading({this.isReloading = false});

  @override
  List<Object> get props => [isReloading];
}

class AccountListLoaded extends AccountListState {
  final List<AssetAccount> accounts;
  const AccountListLoaded({required this.accounts});
  @override
  List<Object> get props => [accounts];
}

class AccountListError extends AccountListState {
  final String message;
  const AccountListError(this.message);
  @override
  List<Object> get props => [message];
}
