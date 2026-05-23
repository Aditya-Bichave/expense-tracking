import 'package:expense_tracker/features/add_expense/data/repositories/outbox_add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late OutboxAddExpenseRepository repository;
  late MockOutboxRepository mockOutbox;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(
      SyncMutationModel(
        id: 'test',
        table: 'test',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockOutbox = MockOutboxRepository();
    mockUuid = MockUuid();
    repository = OutboxAddExpenseRepository(outbox: mockOutbox, uuid: mockUuid);
  });

  test('createExpense adds mutation to outbox', () async {
    const fakeId = '123-abc';
    when(() => mockUuid.v4()).thenReturn(fakeId);
    when(() => mockOutbox.add(any())).thenAnswer((_) async {});

    final state = AddExpenseWizardState(
      amountTotal: 100,
      expenseDate: DateTime(2023),
      transactionId: 'test_tx',
    );
    await repository.createExpense(state);

    final captured =
        verify(() => mockOutbox.add(captureAny())).captured.first
            as SyncMutationModel;

    expect(captured.id, fakeId);
    expect(captured.table, 'rpc/create_expense_transaction');
    expect(captured.operation, OpType.create);
    expect(captured.payload['p_amount_total'], 100);
  });

  test(
    'createExpense includes x_local_receipt_path if cloud url missing',
    () async {
      const fakeId = '123-abc';
      when(() => mockUuid.v4()).thenReturn(fakeId);
      when(() => mockOutbox.add(any())).thenAnswer((_) async {});

      final state = AddExpenseWizardState(
        amountTotal: 100,
        expenseDate: DateTime(2023),
        receiptLocalPath: '/path/to/receipt.jpg',
        transactionId: 'test_tx',
      );
      await repository.createExpense(state);

      final captured =
          verify(() => mockOutbox.add(captureAny())).captured.first
              as SyncMutationModel;

      expect(captured.payload['x_local_receipt_path'], '/path/to/receipt.jpg');
    },
  );

  test('saveReceipt does nothing', () async {
    await repository.saveReceipt('path', 'id');
  });
}
