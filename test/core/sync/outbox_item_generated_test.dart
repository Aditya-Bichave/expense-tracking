import 'dart:typed_data';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  group('OutboxItemAdapter', () {
    test('should match typeId', () {
      final adapter = OutboxItemAdapter();
      expect(adapter.typeId, 12);
    });

    test('should have correct hashCode', () {
      final adapter = OutboxItemAdapter();
      expect(adapter.hashCode, 12.hashCode);
    });

    test('should match equality', () {
      final adapter1 = OutboxItemAdapter();
      final adapter2 = OutboxItemAdapter();
      expect(adapter1 == adapter2, true);
    });
  });
}
