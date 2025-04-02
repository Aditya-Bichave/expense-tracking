part of 'account_list_bloc.dart';

abstract class AccountListState extends Equatable {
  const AccountListState();
  @override
  List<Object> get props => [];
}

class AccountListInitial extends AccountListState {}

class AccountListLoading extends AccountListState {}

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
