part of 'add_edit_income_bloc.dart';

// Reusing FormStatus from Expense feature for simplicity
// enum FormStatus { initial, submitting, success, error }

class AddEditIncomeState extends Equatable {
  final FormStatus status;
  final String? errorMessage;
  final Income? initialIncome; // Store the income being edited

  const AddEditIncomeState({
    this.status = FormStatus.initial,
    this.errorMessage,
    this.initialIncome,
  });

  AddEditIncomeState copyWith({
    FormStatus? status,
    String? errorMessage,
    Income? initialIncome,
    bool clearError = false,
  }) {
    return AddEditIncomeState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      initialIncome: initialIncome ?? this.initialIncome,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, initialIncome];
}
