part of 'add_edit_expense_bloc.dart';

enum FormStatus { initial, submitting, success, error }

class AddEditExpenseState extends Equatable {
  final FormStatus status;
  final String? errorMessage;
  final Expense? initialExpense; // Store the expense being edited

  const AddEditExpenseState({
    this.status = FormStatus.initial,
    this.errorMessage,
    this.initialExpense,
  });

  // Helper method to create a copy with updated values
  AddEditExpenseState copyWith({
    FormStatus? status,
    String? errorMessage,
    Expense? initialExpense, // Allow updating initialExpense if needed
    bool clearError = false, // Helper to clear error message
  }) {
    return AddEditExpenseState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      initialExpense: initialExpense ?? this.initialExpense,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, initialExpense];
}
