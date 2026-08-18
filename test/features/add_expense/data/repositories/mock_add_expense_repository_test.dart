import 'package:expense_tracker/features/add_expense/data/repositories/mock_add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/domain/repositories/add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockAddExpenseRepository repository;

  final state = AddExpenseWizardState(
    amountTotal: 42.5,
    description: 'Team lunch',
    expenseDate: DateTime(2024, 5, 1),
    transactionId: 't-1',
    currentUserId: 'u1',
  );

  setUp(() {
    repository = MockAddExpenseRepository();
  });

  test('satisfies the AddExpenseRepository contract', () {
    expect(repository, isA<AddExpenseRepository>());
  });

  test('createExpense serialises the wizard state and completes', () async {
    // The mock logs `state.toApiPayload()`, so a state that cannot be
    // serialised would throw here rather than completing.
    await expectLater(repository.createExpense(state), completes);
    expect(state.toApiPayload()['p_amount_total'], 42.5);
    expect(state.toApiPayload()['p_client_generated_id'], 't-1');
  });

  test('saveReceipt is a no-op that completes', () async {
    await expectLater(repository.saveReceipt('/tmp/a.png', 'e1'), completes);
  });
}
