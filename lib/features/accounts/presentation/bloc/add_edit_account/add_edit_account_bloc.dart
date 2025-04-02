import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
// Reusing FormStatus enum
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/add_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/update_asset_account.dart';
import 'package:uuid/uuid.dart';

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
  })  : _addAssetAccountUseCase = addAssetAccountUseCase,
        _updateAssetAccountUseCase = updateAssetAccountUseCase,
        _uuid = const Uuid(),
        super(AddEditAccountState(initialAccount: initialAccount)) {
    on<SaveAccountRequested>(_onSaveAccountRequested);
  }

  Future<void> _onSaveAccountRequested(
      SaveAccountRequested event, Emitter<AddEditAccountState> emit) async {
    emit(state.copyWith(status: FormStatus.submitting, clearError: true));

    // Create the entity WITHOUT the current balance - repo calculates it
    final accountData = AssetAccount(
      id: event.existingAccountId ?? _uuid.v4(),
      name: event.name,
      type: event.type,
      initialBalance: event.initialBalance,
      currentBalance:
          0, // Placeholder - Repo impl will calculate actual balance
    );

    final result = event.existingAccountId != null
        ? await _updateAssetAccountUseCase(
            UpdateAssetAccountParams(accountData))
        : await _addAssetAccountUseCase(AddAssetAccountParams(accountData));

    result.fold(
      (failure) {
        emit(state.copyWith(
            status: FormStatus.error,
            errorMessage: _mapFailureToMessage(failure)));
      },
      // Success - the result from use case contains the calculated balance
      (savedAccount) => emit(state.copyWith(status: FormStatus.success)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message;
      case CacheFailure:
        return 'Database Error: ${failure.message}';
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }
}
