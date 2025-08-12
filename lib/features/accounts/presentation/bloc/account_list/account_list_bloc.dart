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
    on<LoadAccounts>(_onLoadAccounts);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
    on<_DataChanged>(_onDataChanged);
    on<ResetState>(_onResetState); // Add handler

    _dataChangeSubscription = dataChangeStream.listen((event) {
      // --- Listen for System Reset ---
      if (event.type == DataChangeType.system &&
          event.reason == DataChangeReason.reset) {
        log.info(
            "[AccountListBloc] System Reset event received. Adding ResetState.");
        add(const ResetState());
      } else if (event.type == DataChangeType.account ||
          event.type == DataChangeType.income ||
          event.type == DataChangeType.expense ||
          event.type == DataChangeType.settings) {
        log.info(
            "[AccountListBloc] Relevant DataChangedEvent: $event. Triggering reload.");
        add(const _DataChanged());
      }
      // --- End System Reset Handling ---
    }, onError: (error, stackTrace) {
      log.severe("[AccountListBloc] Error in dataChangeStream listener");
    });

    log.info("[AccountListBloc] Initialized and subscribed to data changes.");
  }

  // --- ADDED: Reset State Handler ---
  void _onResetState(ResetState event, Emitter<AccountListState> emit) {
    log.info("[AccountListBloc] Resetting state to initial.");
    emit(const AccountListInitial());
    // Trigger initial load after resetting
    add(const LoadAccounts());
  }
  // --- END ADDED ---

  // ... rest of the handlers (_onDataChanged, _onLoadAccounts, _onDeleteAccountRequested, _mapFailureToMessage, close) remain the same ...
  // Internal event handler to trigger reload
  Future<void> _onDataChanged(
      _DataChanged event, Emitter<AccountListState> emit) async {
    if (state is! AccountListLoading) {
      log.info(
          "[AccountListBloc] Handling _DataChanged event. Dispatching LoadAccounts(forceReload: true).");
      add(const LoadAccounts(forceReload: true));
    }
  }

  Future<void> _onLoadAccounts(
      LoadAccounts event, Emitter<AccountListState> emit) async {
    log.info(
        "[AccountListBloc] Received LoadAccounts event (forceReload: ${event.forceReload}). Current state: ${state.runtimeType}");

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
          emit(AccountListError(_mapFailureToMessage(failure)));
        },
        (accounts) {
          log.info(
              "[AccountListBloc] Load successful. Emitting AccountListLoaded with ${accounts.length} accounts.");
          emit(AccountListLoaded(accounts: accounts));
        },
      );
    } catch (e) {
      log.severe("[AccountListBloc] Unexpected error in _onLoadAccounts");
      emit(AccountListError(
          "An unexpected error occurred while loading accounts: ${e.toString()}"));
    }
  }

  Future<void> _onDeleteAccountRequested(
      DeleteAccountRequested event, Emitter<AccountListState> emit) async {
    log.info(
        "[AccountListBloc] Received DeleteAccountRequested for ID: ${event.accountId}");
    final currentState = state;

    if (currentState is AccountListLoaded) {
      log.info(
          "[AccountListBloc] Current state is Loaded. Performing optimistic delete.");
      // Optimistic UI Update using 'items' from base state
      final optimisticList =
          currentState.items.where((acc) => acc.id != event.accountId).toList();
      log.info(
          "[AccountListBloc] Optimistic list size: ${optimisticList.length}. Emitting updated AccountListLoaded.");
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
      } catch (e) {
        log.severe(
            "[AccountListBloc] Unexpected error in _onDeleteAccountRequested for ID ${event.accountId}");
        emit(currentState); // Revert optimistic update
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
