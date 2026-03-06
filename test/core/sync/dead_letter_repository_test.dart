import 'package:expense_tracker/core/sync/dead_letter_repository.dart';
import 'package:expense_tracker/core/sync/models/dead_letter_model.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox<T> extends Mock implements Box<T> {}

class MockDeadLetterModel extends Mock implements DeadLetterModel {}

void main() {
  late DeadLetterRepository repository;
  late MockBox<DeadLetterModel> mockBox;

  setUp(() {
    mockBox = MockBox<DeadLetterModel>();
    repository = DeadLetterRepository(mockBox);
  });

  group('DeadLetterRepository', () {
    test('add should add item to box', () async {
      final item = MockDeadLetterModel();
      when(() => mockBox.add(item)).thenAnswer((_) async => 1);

      await repository.add(item);

      verify(() => mockBox.add(item)).called(1);
    });

    test('getItems should return items sorted by failedAt', () {
      final item1 = DeadLetterModel(
        id: '1',
        table: 'table1',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime(2023),
        failedAt: DateTime(2023, 1, 2),
        lastError: 'error',
        retryCount: 1,
      );
      final item2 = DeadLetterModel(
        id: '2',
        table: 'table1',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime(2023),
        failedAt: DateTime(2023, 1, 1),
        lastError: 'error',
        retryCount: 1,
      );

      when(() => mockBox.values).thenReturn([item1, item2]);

      final result = repository.getItems();

      expect(result.length, 2);
      expect(result.first.id, '2'); // failedAt earlier
      expect(result.last.id, '1');
    });

    test('deleteItem should call delete on the item', () async {
      final item = MockDeadLetterModel();
      when(() => item.delete()).thenAnswer((_) async {});

      await repository.deleteItem(item);

      verify(() => item.delete()).called(1);
    });

    test('clear should clear box', () async {
      when(() => mockBox.clear()).thenAnswer((_) async => 0);

      await repository.clear();

      verify(() => mockBox.clear()).called(1);
    });
  });
}
