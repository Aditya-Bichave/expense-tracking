import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/data/repository/unified_repository.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockBox<T> extends Mock implements Box<T> {}
class MockOutboxRepository extends Mock implements OutboxRepository {}
class MockHiveObject extends Mock implements HiveObject {
  String get id => 'test-id';
}

// Concrete implementation for testing
class TestUnifiedRepository extends UnifiedRepository<MockHiveObject> {
  TestUnifiedRepository({
    required super.localBox,
    required super.outboxRepository,
  });
}

void main() {
  late TestUnifiedRepository repository;
  late MockBox<MockHiveObject> mockBox;
  late MockOutboxRepository mockOutboxRepository;
  late MockHiveObject mockItem;

  setUp(() {
    mockBox = MockBox();
    mockOutboxRepository = MockOutboxRepository();
    mockItem = MockHiveObject();
    repository = TestUnifiedRepository(
      localBox: mockBox,
      outboxRepository: mockOutboxRepository,
    );

    registerFallbackValue(OutboxItem(
        id: '1',
        entityId: '1',
        entityType: EntityType.expense,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime.now()));

    // Register fake for MockHiveObject to fix "any()" error
    registerFallbackValue(MockHiveObject());
  });

  group('UnifiedRepository', () {
    test('add saves to local box and queues outbox item', () async {
      when(() => mockBox.add(any())).thenAnswer((_) async => 1);
      when(() => mockOutboxRepository.add(any())).thenAnswer((_) async => {});

      final result = await repository.add(
        mockItem,
        tableName: 'expenses',
        toJson: (_) => {'key': 'value'},
      );

      expect(result.isRight(), true);
      verify(() => mockBox.add(mockItem)).called(1);
      verify(() => mockOutboxRepository.add(any(that: isA<OutboxItem>()))).called(1);
    });

    test('update saves item and queues outbox item', () async {
      when(() => mockItem.save()).thenAnswer((_) async => {});
      when(() => mockOutboxRepository.add(any())).thenAnswer((_) async => {});

      final result = await repository.update(
        mockItem,
        tableName: 'expenses',
        toJson: (_) => {'key': 'value'},
      );

      expect(result.isRight(), true);
      verify(() => mockItem.save()).called(1);
      verify(() => mockOutboxRepository.add(any(that: isA<OutboxItem>()))).called(1);
    });

    test('delete removes item and queues outbox item', () async {
      when(() => mockItem.delete()).thenAnswer((_) async => {});
      when(() => mockOutboxRepository.add(any())).thenAnswer((_) async => {});

      final result = await repository.delete(
        mockItem,
        tableName: 'expenses',
      );

      expect(result.isRight(), true);
      verify(() => mockItem.delete()).called(1);
      verify(() => mockOutboxRepository.add(any(that: isA<OutboxItem>()))).called(1);
    });
  });
}
