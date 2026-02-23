import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<SyncMutationModel> {}

class FakeSyncMutationModel extends Fake implements SyncMutationModel {}

void main() {
  late OutboxRepository repository;
  late MockBox mockBox;

  setUpAll(() {
    registerFallbackValue(FakeSyncMutationModel());
  });

  setUp(() {
    mockBox = MockBox();
    repository = OutboxRepository(mockBox);
  });

  group('add', () {
    test('should add item to box', () async {
      final item = SyncMutationModel(
        id: '1',
        table: 'groups',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
      );
      when(() => mockBox.add(any())).thenAnswer((_) async => 1);

      await repository.add(item);

      verify(() => mockBox.add(item)).called(1);
    });
  });

  group('getPendingItems', () {
    test('should return pending items', () {
      final item = SyncMutationModel(
        id: '1',
        table: 'groups',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
        status: SyncStatus.pending,
      );
      when(() => mockBox.values).thenReturn([item]);

      final result = repository.getPendingItems();

      expect(result.length, 1);
      expect(result.first, item);
    });

    test('should return failed items', () {
      final item = SyncMutationModel(
        id: '2',
        table: 'groups',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
        status: SyncStatus.failed,
        lastError: 'error',
      );
      when(() => mockBox.values).thenReturn([item]);

      final result = repository.getPendingItems();

      expect(result.length, 1);
      expect(result.first, item);
    });

    test('should sort items by createdAt', () {
      final item1 = SyncMutationModel(
        id: '1',
        table: 'groups',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now().add(const Duration(seconds: 10)),
      );
      final item2 = SyncMutationModel(
        id: '2',
        table: 'groups',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
      );
      when(() => mockBox.values).thenReturn([item1, item2]);

      final result = repository.getPendingItems();

      expect(result.length, 2);
      expect(result[0], item2);
      expect(result[1], item1);
    });
  });

  group('markAsSent', () {
    test('should call delete on the item', () async {
      final mockItem = MockSyncMutationModel();
      when(() => mockItem.delete()).thenAnswer((_) async {});

      await repository.markAsSent(mockItem);

      verify(() => mockItem.delete()).called(1);
    });
  });

  group('markAsFailed', () {
    test('should mark as failed, update properties, and save', () async {
      final mockItem = MockSyncMutationModel();

      // Since it's a mock, setting properties doesn't do anything by default
      // but we can verify the setters are called with correct values,
      // OR we can just use a real model and mock the box (which the previous test did).
      // But a real model fails on `save()` if not in a box. We will mock `save()` using Mock.

      var retryCount = 0;
      when(() => mockItem.retryCount).thenReturn(retryCount);
      when(
        () => mockItem.retryCount = any(),
      ).thenAnswer((i) => retryCount = i.positionalArguments.first);

      when(() => mockItem.save()).thenAnswer((_) async {});

      await repository.markAsFailed(mockItem, 'error');

      verify(() => mockItem.lastError = 'error').called(1);
      verify(() => mockItem.retryCount = 1).called(1);
      verify(() => mockItem.save()).called(1);
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

class MockSyncMutationModel extends Mock implements SyncMutationModel {}
