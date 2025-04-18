part of 'account_list_bloc.dart';

abstract class AccountListEvent extends Equatable {
  const AccountListEvent();
  @override
  List<Object> get props => [];
}

class LoadAccounts extends AccountListEvent {
  final bool forceReload;
  const LoadAccounts({this.forceReload = false});

  @override
  List<Object> get props => [forceReload];
}

class DeleteAccountRequested extends AccountListEvent {
  final String accountId;
  const DeleteAccountRequested(this.accountId);
  @override
  List<Object> get props => [accountId];
}

// Internal event triggered by stream listener or other actions needing refresh
class _DataChanged extends AccountListEvent {
  const _DataChanged();
}

// --- ADDED: Reset State Event ---
class ResetState extends AccountListEvent {
  const ResetState();
}
// --- END ADDED ---
