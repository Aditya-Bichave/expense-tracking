part of 'add_edit_account_bloc.dart';

// Reusing FormStatus enum
// enum FormStatus { initial, submitting, success, error }

class AddEditAccountState extends Equatable {
  final FormStatus status;
  final String? errorMessage;
  final AssetAccount? initialAccount; // Store account being edited

  const AddEditAccountState({
    this.status = FormStatus.initial,
    this.errorMessage,
    this.initialAccount,
  });

  AddEditAccountState copyWith({
    FormStatus? status,
    String? errorMessage,
    AssetAccount? initialAccount,
    bool clearError = false,
  }) {
    return AddEditAccountState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      initialAccount: initialAccount ?? this.initialAccount,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, initialAccount];
}
