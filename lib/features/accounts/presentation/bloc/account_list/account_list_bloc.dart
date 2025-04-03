// lib/features/accounts/presentation/bloc/account_list/account_list_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart'; // For NoParams
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/delete_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl helper
import 'package:expense_tracker/core/events/data_change_event.dart'; // Import event

// Import the specific states for this BLoC
part 'account_list_event.dart';
part 'account_list_state.dart';

class AccountListBloc extends Bloc<AccountListEvent, AccountListState> {
  final GetAssetAccountsUseCase _getAssetAccountsUseCase;
  final DeleteAssetAccountUseCase _deleteAssetAccountUseCase;
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  AccountListBloc({
    required GetAssetAccountsUseCase getAssetAccountsUseCase,
    required DeleteAssetAccountUseCase deleteAssetAccountUseCase,
    required Stream<DataChangedEvent> dataChangeStream,
  })  : _getAssetAccountsUseCase = getAssetAccountsUseCase,
        _deleteAssetAccountUseCase = deleteAssetAccountUseCase,
        super(const AccountListInitial()) {
    // Use const constructor
    on<LoadAccounts>(_onLoadAccounts);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
    on<_DataChanged>(_onDataChanged);

    _dataChangeSubscription = dataChangeStream.listen((event) {
      // Accounts list needs refresh if Accounts, Income, or Expenses change (for balances) or Settings (currency)
      if (event.type == DataChangeType.account ||
          event.type == DataChangeType.income ||
          event.type == DataChangeType.expense ||
          event.type == DataChangeType.settings) {
        log.info(
            "[AccountListBloc] Received relevant DataChangedEvent: $event. Triggering reload.");
        add(const _DataChanged());
      }
    }, onError: (error, stackTrace) {
      log.severe("[AccountListBloc] Error in dataChangeStream listener");
    });

    log.info("[AccountListBloc] Initialized and subscribed to data changes.");
  }

  // Internal event handler to trigger reload
  Future<void> _onDataChanged(
      _DataChanged event, Emitter<AccountListState> emit) async {
    log.info(
        "[AccountListBloc] Handling _DataChanged event. Dispatching LoadAccounts(forceReload: true).");
    add(const LoadAccounts(forceReload: true));
  }

  Future<void> _onLoadAccounts(
      LoadAccounts event, Emitter<AccountListState> emit) async {
    log.info(
        "[AccountListBloc] Received LoadAccounts event (forceReload: ${event.forceReload}). Current state: ${state.runtimeType}");

    // --- CHANGE: Emit new Loading state ---
    if (state is! AccountListLoaded || event.forceReload) {
      emit(AccountListLoading(isReloading: state is AccountListLoaded));
      log.info(
          "[AccountListBloc] Emitting AccountListLoading (isReloading: ${state is AccountListLoaded}).");
    } else {
      log.info(
          "[AccountListBloc] State is AccountListLoaded and no force reload. Refreshing data silently.");
    }

    try {
      final result = await _getAssetAccountsUseCase(const NoParams());
      log.info(
          "[AccountListBloc] GetAssetAccountsUseCase returned. isLeft: ${result.isLeft()}");

      result.fold(
        (failure) {
          log.warning(
              "[AccountListBloc] Load failed: ${failure.message}. Emitting AccountListError.");
          // --- CHANGE: Emit new Error state ---
          emit(AccountListError(_mapFailureToMessage(failure)));
        },
        (accounts) {
          log.info(
              "[AccountListBloc] Load successful. Emitting AccountListLoaded with ${accounts.length} accounts.");
          // --- CHANGE: Emit new Loaded state ---
          emit(AccountListLoaded(accounts: accounts));
        },
      );
    } catch (e, s) {
      log.severe("[AccountListBloc] Unexpected error in _onLoadAccounts");
      // --- CHANGE: Emit new Error state ---
      emit(AccountListError(
          "An unexpected error occurred while loading accounts: ${e.toString()}"));
    }
  }

  Future<void> _onDeleteAccountRequested(
      DeleteAccountRequested event, Emitter<AccountListState> emit) async {
    log.info(
        "[AccountListBloc] Received DeleteAccountRequested for ID: ${event.accountId}");
    final currentState = state;

    // --- CHANGE: Check for new Loaded state ---
    if (currentState is AccountListLoaded) {
      log.info(
          "[AccountListBloc] Current state is Loaded. Performing optimistic delete.");
      // Optimistic UI Update using 'items' from base state
      final optimisticList =
          currentState.items.where((acc) => acc.id != event.accountId).toList();
      log.info(
          "[AccountListBloc] Optimistic list size: ${optimisticList.length}. Emitting updated AccountListLoaded.");
      // --- CHANGE: Emit new Loaded state ---
      emit(AccountListLoaded(accounts: optimisticList));

      try {
        final result = await _deleteAssetAccountUseCase(
            DeleteAssetAccountParams(event.accountId));
        log.info(
            "[AccountListBloc] DeleteAssetAccountUseCase returned. isLeft: ${result.isLeft()}");

        result.fold(
          (failure) {
            log.warning(
                "[AccountListBloc] Deletion failed: ${failure.message}. Reverting UI and emitting Error.");
            // Revert UI
            emit(currentState);
            // --- CHANGE: Emit new Error state ---
            emit(AccountListError(_mapFailureToMessage(failure,
                context: "Failed to delete account")));
          },
          (_) {
            log.info(
                "[AccountListBloc] Deletion successful. Publishing DataChangedEvent.");
            publishDataChangedEvent(
                type: DataChangeType.account, reason: DataChangeReason.deleted);
          },
        );
      } catch (e, s) {
        log.severe(
            "[AccountListBloc] Unexpected error in _onDeleteAccountRequested for ID ${event.accountId}");
        emit(currentState); // Revert optimistic update
        // --- CHANGE: Emit new Error state ---
        emit(AccountListError(
            "An unexpected error occurred during deletion: ${e.toString()}"));
      }
    } else {
      log.warning(
          "[AccountListBloc] Delete requested but state is not AccountListLoaded. Ignoring.");
    }
  }

  String _mapFailureToMessage(Failure failure,
      {String context = "An error occurred"}) {
    log.warning(
        "[AccountListBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
    String specificMessage;
    switch (failure.runtimeType) {
      case CacheFailure:
        specificMessage = 'Database Error: ${failure.message}';
        break;
      case ValidationFailure:
        specificMessage = failure.message;
        break;
      case UnexpectedFailure:
        specificMessage = 'An unexpected error occurred. Please try again.';
        break;
      default:
        specificMessage = failure.message.isNotEmpty
            ? failure.message
            : 'An unknown error occurred.';
        break;
    }
    return "$context: $specificMessage";
  }

  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    log.info(
        "[AccountListBloc] Canceled data change subscription and closing.");
    return super.close();
  }
}
