import 'package:expense_tracker/features/add_expense/domain/repositories/add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class MockAddExpenseRepository implements AddExpenseRepository {
  @override
  Future<void> createExpense(AddExpenseWizardState state) async {
    final payload = state.toApiPayload();
    log.info('---------------- MOCK CREATE EXPENSE ----------------');
    log.info('Payload: ');
    log.info('-----------------------------------------------------');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> saveReceipt(String localPath, String expenseId) async {
    // No-op for mock
  }
}
