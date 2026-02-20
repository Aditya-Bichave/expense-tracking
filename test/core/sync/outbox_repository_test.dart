import 'package:expense_tracker/core/constants/hive_constants.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox<T> extends Mock implements Box<T> {}

void main() {
  late OutboxRepository repository;
  late MockBox<OutboxItem> mockBox;

  setUp(() {
    mockBox = MockBox();
    repository = OutboxRepository(mockBox);
  });

  final tItem = OutboxItem(
    id: '1',
    entityId: '100', // Added entityId
    entityType: EntityType.group,
    opType: OpType.create,
    payloadJson: '{}',
    createdAt: DateTime.now(),
  );

  group('OutboxRepository', () {
    test('add should add item to box', () async {
      when(() => mockBox.add(tItem)).thenAnswer((_) async => 1);

      await repository.add(tItem);

      verify(() => mockBox.add(tItem));
    });

    test('getPendingItems should return list of pending items', () {
      when(() => mockBox.values).thenReturn([tItem]);

      final result = repository.getPendingItems();

      expect(result, [tItem]);
    });

    test('clear should clear box', () async {
      when(() => mockBox.clear()).thenAnswer((_) async => 0);

      await repository.clear();

      verify(() => mockBox.clear());
    });
  });
}
