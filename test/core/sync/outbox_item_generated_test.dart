import 'dart:io';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as path;

void main() {
  group('OutboxItemAdapter Integration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(12)) {
        Hive.registerAdapter(OutboxItemAdapter());
      }
      if (!Hive.isAdapterRegistered(20)) {
        Hive.registerAdapter(OutboxStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(21)) {
        Hive.registerAdapter(OpTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(22)) {
        Hive.registerAdapter(EntityTypeAdapter());
      }
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should read and write OutboxItem correctly via Hive', () async {
      final box = await Hive.openBox<OutboxItem>('outbox_items');

      final item = OutboxItem(
        id: '1',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{"test": "data"}',
        createdAt: DateTime.utc(2024, 1, 1),
        status: OutboxStatus.pending,
        nextRetryAt: DateTime.utc(2025, 1, 1),
        lastError: 'error',
        retryCount: 1,
      );

      await box.put('key1', item);

      await box.close();
      final reOpenedBox = await Hive.openBox<OutboxItem>('outbox_items');

      final retrievedItem = reOpenedBox.get('key1');

      expect(retrievedItem, isNotNull);
      expect(retrievedItem!.id, item.id);
      expect(retrievedItem.entityType, item.entityType);
      expect(retrievedItem.opType, item.opType);
      expect(retrievedItem.payloadJson, item.payloadJson);
      expect(retrievedItem.createdAt, item.createdAt);
      expect(retrievedItem.status, item.status);
      expect(retrievedItem.nextRetryAt, item.nextRetryAt);
      expect(retrievedItem.lastError, item.lastError);
      expect(retrievedItem.retryCount, item.retryCount);
    });
  });
}
