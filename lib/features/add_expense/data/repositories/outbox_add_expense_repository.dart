import 'package:expense_tracker/features/add_expense/domain/repositories/add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:uuid/uuid.dart';

class OutboxAddExpenseRepository implements AddExpenseRepository {
  final OutboxRepository outbox;
  final Uuid uuid;

  OutboxAddExpenseRepository({required this.outbox, required this.uuid});

  @override
  Future<void> createExpense(AddExpenseWizardState state) async {
    final payload = state.toApiPayload();

    // If receipt URL is missing but local path exists, include it for SyncEngine handling
    if (state.receiptCloudUrl == null && state.receiptLocalPath != null) {
      payload['x_local_receipt_path'] = state.receiptLocalPath;
    }

    final mutation = SyncMutationModel(
      id: uuid.v4(),
      table: 'rpc/create_expense_transaction',
      operation: OpType.create,
      payload: payload,
      createdAt: DateTime.now(),
    );

    await outbox.add(mutation);
  }

  @override
  Future<void> saveReceipt(String localPath, String expenseId) async {
    // Managed via UI flow or x_local_receipt_path
  }
}
