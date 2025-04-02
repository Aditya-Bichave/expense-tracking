import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart'; // For NoParams
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/delete_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';

part 'account_list_event.dart';
part 'account_list_state.dart';

class AccountListBloc extends Bloc<AccountListEvent, AccountListState> {
  final GetAssetAccountsUseCase _getAssetAccountsUseCase;
  final DeleteAssetAccountUseCase _deleteAssetAccountUseCase;

  AccountListBloc({
    required GetAssetAccountsUseCase getAssetAccountsUseCase,
    required DeleteAssetAccountUseCase deleteAssetAccountUseCase,
  })  : _getAssetAccountsUseCase = getAssetAccountsUseCase,
        _deleteAssetAccountUseCase = deleteAssetAccountUseCase,
        super(AccountListInitial()) {
    on<LoadAccounts>(_onLoadAccounts);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
    debugPrint("[AccountListBloc] Initialized.");
  }

  Future<void> _onLoadAccounts(
      LoadAccounts event, Emitter<AccountListState> emit) async {
    debugPrint("[AccountListBloc] Received LoadAccounts event.");
    // Prevent emitting Loading if already Loaded to avoid UI flicker on refresh
    if (state is! AccountListLoaded) {
      debugPrint(
          "[AccountListBloc] Current state is not Loaded. Emitting AccountListLoading.");
      emit(AccountListLoading());
    } else {
      debugPrint(
          "[AccountListBloc] Current state is Loaded. Refreshing data without emitting Loading.");
    }

    try {
      final result = await _getAssetAccountsUseCase(NoParams());
      debugPrint(
          "[AccountListBloc] GetAssetAccountsUseCase returned. Result isLeft: ${result.isLeft()}");

      result.fold(
        (failure) {
          debugPrint(
              "[AccountListBloc] Emitting AccountListError: ${failure.message}");
          emit(AccountListError(_mapFailureToMessage(failure)));
        },
        (accounts) {
          debugPrint(
              "[AccountListBloc] Emitting AccountListLoaded with ${accounts.length} accounts.");
          emit(AccountListLoaded(accounts: accounts));
        },
      );
    } catch (e, s) {
      debugPrint(
          "[AccountListBloc] *** CRITICAL ERROR in _onLoadAccounts: $e\n$s");
      emit(AccountListError(
          "An unexpected error occurred in the Account BLoC: $e"));
    } finally {
      debugPrint(
          "[AccountListBloc] Finished processing LoadAccounts event handler.");
    }
  }

  Future<void> _onDeleteAccountRequested(
      DeleteAccountRequested event, Emitter<AccountListState> emit) async {
    debugPrint(
        "[AccountListBloc] Received DeleteAccountRequested for ID: ${event.accountId}");
    final currentState = state;
    if (currentState is AccountListLoaded) {
      debugPrint(
          "[AccountListBloc] Current state is Loaded. Proceeding with optimistic delete.");
      // Optimistic UI Update
      final optimisticList = currentState.accounts
          .where((acc) => acc.id != event.accountId)
          .toList();
      debugPrint(
          "[AccountListBloc] Optimistic list size: ${optimisticList.length}. Emitting updated AccountListLoaded.");
      emit(AccountListLoaded(accounts: optimisticList));

      try {
        final result = await _deleteAssetAccountUseCase(
            DeleteAssetAccountParams(event.accountId));
        debugPrint(
            "[AccountListBloc] DeleteAssetAccountUseCase returned. Result isLeft: ${result.isLeft()}");

        result.fold(
          (failure) {
            debugPrint(
                "[AccountListBloc] Deletion failed: ${failure.message}. Reverting UI and emitting Error.");
            // Revert UI and show error
            emit(currentState); // Revert to previous list
            emit(AccountListError(
                "Failed to delete account: ${_mapFailureToMessage(failure)}. Check linked transactions."));
            // Optionally reload to be absolutely sure: add(LoadAccounts());
          },
          (_) {
            // Optimistic update was successful, no state change needed
            debugPrint(
                "[AccountListBloc] Deletion successful (Optimistic UI).");
            // If not using optimistic update, trigger: add(LoadAccounts());
          },
        );
      } catch (e, s) {
        debugPrint(
            "[AccountListBloc] *** CRITICAL ERROR in _onDeleteAccountRequested: $e\n$s");
        emit(currentState); // Revert optimistic update on error
        emit(AccountListError(
            "An unexpected error occurred during deletion: $e"));
      }
    } else {
      debugPrint(
          "[AccountListBloc] Delete requested but state is not AccountListLoaded. Ignoring.");
    }
    debugPrint("[AccountListBloc] Finished processing DeleteAccountRequested.");
  }

  String _mapFailureToMessage(Failure failure) {
    // Customize error messages for accounts
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'Database Error: ${failure.message}';
      case ValidationFailure:
        return failure.message; // Use specific validation message
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }
}
