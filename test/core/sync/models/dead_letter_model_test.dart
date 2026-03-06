import 'package:expense_tracker/core/sync/models/dead_letter_model.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeadLetterModel', () {
    test('fromSyncMutation creates model correctly', () {
      final syncMutation = SyncMutationModel(
        id: '1',
        table: 'expenses',
        operation: OpType.update,
        payload: {'key': 'value'},
        createdAt: DateTime(2023, 1, 1),
        retryCount: 3,
        status: SyncStatus.failed,
        lastError: 'Test error',
      );

      final deadLetter = DeadLetterModel.fromSyncMutation(syncMutation);

      expect(deadLetter.id, '1');
      expect(deadLetter.table, 'expenses');
      expect(deadLetter.operation, OpType.update);
      expect(deadLetter.payload, {'key': 'value'});
      expect(deadLetter.createdAt, DateTime(2023, 1, 1));
      expect(deadLetter.lastError, 'Test error');
      expect(deadLetter.retryCount, 3);
      expect(deadLetter.failedAt, isNotNull);
    });

    test('fromSyncMutation handles null lastError', () {
      final syncMutation = SyncMutationModel(
        id: '1',
        table: 'expenses',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
      ); // lastError is null by default

      final deadLetter = DeadLetterModel.fromSyncMutation(syncMutation);

      expect(deadLetter.lastError, 'Unknown error');
    });

    test('toSyncMutation creates valid pending mutation', () {
      final deadLetter = DeadLetterModel(
        id: '2',
        table: 'groups',
        operation: OpType.delete,
        payload: {'id': '2'},
        createdAt: DateTime(2023, 1, 1),
        failedAt: DateTime(2023, 1, 2),
        lastError: 'Some error',
        retryCount: 5,
      );

      final syncMutation = deadLetter.toSyncMutation();

      expect(syncMutation.id, '2');
      expect(syncMutation.table, 'groups');
      expect(syncMutation.operation, OpType.delete);
      expect(syncMutation.payload, {'id': '2'});
      expect(syncMutation.createdAt, DateTime(2023, 1, 1));
      expect(syncMutation.status, SyncStatus.pending);
      expect(syncMutation.retryCount, 0);
      expect(syncMutation.lastError, isNull);
    });
  });
}
