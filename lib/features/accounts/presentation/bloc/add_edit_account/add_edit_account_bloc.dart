import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/utils/enums.dart'; // Use shared FormStatus
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/add_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/update_asset_account.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl helper & publish
import 'package:expense_tracker/core/events/data_change_event.dart'; // Import event
import 'package:expense_tracker/main.dart'; // Import logger

part 'add_edit_account_event.dart';
part 'add_edit_account_state.dart';

class AddEditAccountBloc
    extends Bloc<AddEditAccountEvent, AddEditAccountState> {
  final AddAssetAccountUseCase _addAssetAccountUseCase;
  final UpdateAssetAccountUseCase _updateAssetAccountUseCase;
  final Uuid _uuid;

  AddEditAccountBloc({
    required AddAssetAccountUseCase addAssetAccountUseCase,
    required UpdateAssetAccountUseCase updateAssetAccountUseCase,
    AssetAccount? initialAccount,
  }) : _addAssetAccountUseCase = addAssetAccountUseCase,
       _updateAssetAccountUseCase = updateAssetAccountUseCase,
       _uuid = const Uuid(),
       super(AddEditAccountState(initialAccount: initialAccount)) {
    on<SaveAccountRequested>(_onSaveAccountRequested);
    log.info(
      "[AddEditAccountBloc] Initialized. Editing: ${initialAccount != null}",
    );
  }

  Future<void> _onSaveAccountRequested(
    SaveAccountRequested event,
    Emitter<AddEditAccountState> emit,
  ) async {
    log.info("[AddEditAccountBloc] Received SaveAccountRequested.");
    emit(state.copyWith(status: FormStatus.submitting, clearError: true));

    final bool isEditing = event.existingAccountId != null;
    // Preserve existing current balance when editing; repository recalculates later
    final currentBalance = isEditing
        ? state.initialAccount?.currentBalance ?? event.initialBalance
        : event.initialBalance;

    final accountData = AssetAccount(
      id: event.existingAccountId ?? _uuid.v4(),
      name: event.name,
      type: event.type,
      initialBalance: event.initialBalance,
      currentBalance: currentBalance,
    );

    log.info(
      "[AddEditAccountBloc] Calling ${isEditing ? 'Update' : 'Add'} use case for '${accountData.name}'.",
    );
    final result = isEditing
        ? await _updateAssetAccountUseCase(
            UpdateAssetAccountParams(accountData),
          )
        : await _addAssetAccountUseCase(AddAssetAccountParams(accountData));

    result.fold(
      (failure) {
        log.warning("[AddEditAccountBloc] Save failed: ${failure.message}");
        emit(
          state.copyWith(
            status: FormStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
      },
      (savedAccount) {
        log.info(
          "[AddEditAccountBloc] Save successful for '${savedAccount.name}'. Emitting Success status and publishing event.",
        );
        emit(state.copyWith(status: FormStatus.success));
        publishDataChangedEvent(
          type: DataChangeType.account,
          reason: isEditing ? DataChangeReason.updated : DataChangeReason.added,
        );
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    log.warning(
      "[AddEditAccountBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}",
    );
    switch (failure) {
      case ValidationFailure _:
        return failure.message;
      case CacheFailure _:
        return 'Database Error: Could not save account. ${failure.message}';
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }
}
