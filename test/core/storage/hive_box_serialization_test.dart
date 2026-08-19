import 'dart:io';

import 'package:expense_tracker/core/storage/hive_adapters.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

/// Real-box serialization tests.
///
/// The fake reader/writer harness in `hive_adapter_harness.dart` proves each
/// adapter's field indices line up, but it hands values straight back without
/// Hive encoding, so it cannot catch a nested adapter that was never
/// registered or a collection that fails to encode. These tests write to an
/// actual box on a temp directory and read it back through a fresh box
/// instance, which exercises the full encode/decode path including adapter
/// dispatch for nested objects.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive-box-serialization');
    Hive.init(tempDir.path);
    HiveAdapters.registerAll();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// Writes [value] to a fresh box, closes it, then reopens and reads it back,
  /// so the value genuinely round-trips through Hive's binary format.
  Future<T> persistAndReload<T>(String boxName, T value) async {
    final box = await Hive.openBox<T>(boxName);
    await box.put('k', value);
    await box.close();

    final reopened = await Hive.openBox<T>(boxName);
    final result = reopened.get('k') as T;
    await reopened.close();
    await Hive.deleteBoxFromDisk(boxName);
    return result;
  }

  group('GroupExpenseModel', () {
    test('nested payers and splits survive a real box round-trip', () async {
      final stored = await persistAndReload(
        'group_expense_nested',
        GroupExpenseModel(
          id: 'ge1',
          groupId: 'grp1',
          createdBy: 'u1',
          title: 'Dinner',
          amount: 90,
          currency: 'USD',
          occurredAt: DateTime(2024, 3, 15),
          createdAt: DateTime(2024, 3, 15),
          updatedAt: DateTime(2024, 3, 16),
          categoryId: 'c-food',
          payers: [
            ExpensePayerModel(userId: 'u1', amount: 60),
            ExpensePayerModel(userId: 'u2', amount: 30),
          ],
          splits: [
            ExpenseSplitModel(
              userId: 'u1',
              amount: 45,
              splitTypeValue: 'exact',
            ),
            ExpenseSplitModel(
              userId: 'u2',
              amount: 45,
              splitTypeValue: 'exact',
            ),
          ],
        ),
      );

      expect(stored.id, 'ge1');
      expect(stored.title, 'Dinner');
      expect(stored.amount, 90);
      expect(stored.categoryId, 'c-food');
      expect(stored.occurredAt, DateTime(2024, 3, 15));
      expect(stored.updatedAt, DateTime(2024, 3, 16));

      // The nested lists are what the fake harness cannot verify: these only
      // come back correctly if ExpensePayerModelAdapter and
      // ExpenseSplitModelAdapter are registered and dispatched.
      expect(stored.payers, hasLength(2));
      expect(stored.payers.map((p) => p.userId), ['u1', 'u2']);
      expect(stored.payers.map((p) => p.amount), [60, 30]);
      expect(stored.splits, hasLength(2));
      expect(stored.splits.every((s) => s.splitTypeValue == 'exact'), isTrue);
      expect(stored.splits.map((s) => s.amount), [45, 45]);
    });

    test('empty participant lists round-trip as empty, not null', () async {
      final stored = await persistAndReload(
        'group_expense_empty',
        GroupExpenseModel(
          id: 'ge2',
          groupId: 'grp1',
          createdBy: 'u1',
          title: 'Coffee',
          amount: 4,
          currency: 'USD',
          occurredAt: DateTime(2024, 3, 15),
          createdAt: DateTime(2024, 3, 15),
          updatedAt: DateTime(2024, 3, 15),
        ),
      );

      expect(stored.payers, isEmpty);
      expect(stored.splits, isEmpty);
      expect(stored.categoryId, isNull);
    });
  });

  group('SyncMutationModel', () {
    test('a nested payload map survives a real box round-trip', () async {
      final stored = await persistAndReload(
        'sync_mutation_payload',
        SyncMutationModel(
          id: 'sm1',
          table: 'expenses',
          operation: OpType.update,
          payload: const {
            'id': 'e1',
            'amount': 42.5,
            'tags': ['food', 'work'],
            'meta': {'source': 'manual', 'retries': 2},
            'archived': false,
          },
          createdAt: DateTime(2024, 3, 15),
          retryCount: 1,
          status: SyncStatus.failed,
          lastError: 'network unreachable',
        ),
      );

      expect(stored.id, 'sm1');
      expect(stored.table, 'expenses');
      expect(stored.operation, OpType.update);
      expect(stored.retryCount, 1);
      expect(stored.status, SyncStatus.failed);
      expect(stored.lastError, 'network unreachable');

      // Scalars, a nested list and a nested map all have to come back intact,
      // or a queued mutation replays with corrupted data.
      expect(stored.payload['id'], 'e1');
      expect(stored.payload['amount'], 42.5);
      expect(stored.payload['archived'], isFalse);
      expect(stored.payload['tags'], ['food', 'work']);
      expect(Map<String, dynamic>.from(stored.payload['meta'] as Map), {
        'source': 'manual',
        'retries': 2,
      });
    });

    test('an empty payload round-trips with the pending defaults', () async {
      final stored = await persistAndReload(
        'sync_mutation_empty',
        SyncMutationModel(
          id: 'sm2',
          table: 'incomes',
          operation: OpType.delete,
          payload: const {},
          createdAt: DateTime(2024, 3, 15),
        ),
      );

      expect(stored.payload, isEmpty);
      expect(stored.retryCount, 0);
      expect(stored.status, SyncStatus.pending);
      expect(stored.lastError, isNull);
      expect(stored.operation, OpType.delete);
    });

    test('every OpType and SyncStatus value survives persistence', () async {
      for (final op in OpType.values) {
        final stored = await persistAndReload(
          'sync_op_${op.name}',
          SyncMutationModel(
            id: 'sm-${op.name}',
            table: 't',
            operation: op,
            payload: const {},
            createdAt: DateTime(2024, 3, 15),
          ),
        );
        expect(stored.operation, op);
      }

      for (final status in SyncStatus.values) {
        final stored = await persistAndReload(
          'sync_status_${status.name}',
          SyncMutationModel(
            id: 'sm-${status.name}',
            table: 't',
            operation: OpType.create,
            payload: const {},
            createdAt: DateTime(2024, 3, 15),
            status: status,
          ),
        );
        expect(stored.status, status);
      }
    });
  });
}
