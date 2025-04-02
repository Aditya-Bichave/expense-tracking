part of 'account_list_bloc.dart';

abstract class AccountListEvent extends Equatable {
  const AccountListEvent();
  @override
  List<Object> get props => [];
}

class LoadAccounts extends AccountListEvent {}

class DeleteAccountRequested extends AccountListEvent {
  final String accountId;
  const DeleteAccountRequested(this.accountId);
  @override
  List<Object> get props => [accountId];
}
