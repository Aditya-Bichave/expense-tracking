import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';

abstract class AddExpenseRepository {
  Future<void> createExpense(AddExpenseWizardState state);
  Future<void> saveReceipt(
    String localPath,
    String expenseId,
  ); // Or maybe integrated
  // The state.toApiPayload() handles the JSON construction.
}
