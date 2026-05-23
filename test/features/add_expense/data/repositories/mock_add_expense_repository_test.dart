import 'package:expense_tracker/features/add_expense/data/repositories/mock_add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockAddExpenseRepository repository;

  setUp(() {
    repository = MockAddExpenseRepository();
  });

  test('createExpense delays and completes', () async {
    final state = AddExpenseWizardState(
      amountTotal: 100,
      expenseDate: DateTime(2023),
      transactionId: 'test_tx',
    );
    await repository.createExpense(state);
    // test completes successfully
  });

  test('saveReceipt does nothing', () async {
    await repository.saveReceipt('path', 'id');
  });
}
