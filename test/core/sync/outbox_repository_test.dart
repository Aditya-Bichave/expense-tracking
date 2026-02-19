import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<OutboxItem> {}

class FakeOutboxItem extends Fake implements OutboxItem {}

void main() {
  late OutboxRepository repository;
  late MockBox mockBox;

  setUpAll(() {
    registerFallbackValue(FakeOutboxItem());
  });

  setUp(() {
    mockBox = MockBox();
    repository = OutboxRepository(mockBox);
  });

  final tItem = OutboxItem(
    id: '1',
    entityType: EntityType.group,
    opType: OpType.create,
    payloadJson: '{}',
    createdAt: DateTime.now(),
  );

  group('add', () {
    test('should add item to box', () async {
      when(() => mockBox.add(any())).thenAnswer((_) async => 1);

      await repository.add(tItem);

      verify(() => mockBox.add(tItem)).called(1);
    });
  });

  group('getPendingItems', () {
    test('should return list of pending items', () {
      // Arrange
      when(() => mockBox.values).thenReturn([tItem]);

      // Act
      final result = repository.getPendingItems();

      // Assert
      expect(result.length, 1);
      expect(result.first, tItem);
    });
  });

  group('clear', () {
    test('should clear box', () async {
      when(() => mockBox.clear()).thenAnswer((_) async => 0);

      await repository.clear();

      verify(() => mockBox.clear()).called(1);
    });
  });
}
