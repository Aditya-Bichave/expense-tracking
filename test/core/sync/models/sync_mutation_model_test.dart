import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncMutationModel', () {
    test('should instantiate with provided values', () {
      final now = DateTime.now();
      final model = SyncMutationModel(
        id: '1',
        table: 'groups',
        operation: OpType.create,
        payload: {'name': 'Test Group'},
        createdAt: now,
      );

      expect(model.id, '1');
      expect(model.table, 'groups');
      expect(model.operation, OpType.create);
      expect(model.payload, {'name': 'Test Group'});
      expect(model.createdAt, now);
      expect(model.retryCount, 0);
      expect(model.status, SyncStatus.pending);
      expect(model.lastError, null);
    });

    test('should allow updating mutable fields', () {
      final now = DateTime.now();
      final model = SyncMutationModel(
        id: '1',
        table: 'groups',
        operation: OpType.create,
        payload: {'name': 'Test Group'},
        createdAt: now,
      );

      model.retryCount = 1;
      model.status = SyncStatus.failed;
      model.lastError = 'Connection failed';

      expect(model.retryCount, 1);
      expect(model.status, SyncStatus.failed);
      expect(model.lastError, 'Connection failed');
    });
  });
}
