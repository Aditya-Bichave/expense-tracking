import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/features/add_expense/data/repositories/mock_add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/domain/repositories/add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_logger/simple_logger.dart';

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

  /// Captures everything written through the shared logger for the duration of
  /// a test, restoring the original sink afterwards.
  List<String> captureLog() {
    final messages = <String>[];
    final previous = log.onLogged;
    log.onLogged = (formatted, info) => messages.add(info.message.toString());
    addTearDown(() => log.onLogged = previous);
    return messages;
  }

  test('satisfies the AddExpenseRepository contract', () {
    expect(repository, isA<AddExpenseRepository>());
  });

  // Regression: this line used to log a bare 'Payload: ' because a UI migration
  // stripped the interpolation, so the mock logged nothing useful at all.
  test('createExpense logs the serialised payload', () async {
    final messages = captureLog();

    await repository.createExpense(state);

    final payloadLine = messages.firstWhere(
      (m) => m.startsWith('Payload: '),
      orElse: () => fail('no payload line was logged; captured: $messages'),
    );
    expect(payloadLine, contains('p_amount_total'));
    expect(payloadLine, contains('42.5'));
    expect(payloadLine, contains('t-1'));
  });

  test('createExpense completes for a serialisable state', () async {
    await expectLater(repository.createExpense(state), completes);
    expect(state.toApiPayload()['p_amount_total'], 42.5);
    expect(state.toApiPayload()['p_client_generated_id'], 't-1');
  });

  test('saveReceipt is a no-op that completes', () async {
    await expectLater(repository.saveReceipt('/tmp/a.png', 'e1'), completes);
  });
}
