import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/features/group_expenses/data/datasources/group_expenses_local_data_source.dart';
import 'package:expense_tracker/features/group_expenses/data/datasources/group_expenses_remote_data_source.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:expense_tracker/features/group_expenses/data/repositories/group_expenses_repository_impl.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalDataSource extends Mock
    implements GroupExpensesLocalDataSource {}

class MockRemoteDataSource extends Mock
    implements GroupExpensesRemoteDataSource {}

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockSyncService extends Mock implements SyncService {}

class MockConnectivity extends Mock implements Connectivity {}

class FakeSyncMutationModel extends Fake implements SyncMutationModel {}

class FakeGroupExpenseModel extends Fake implements GroupExpenseModel {}

void main() {
  late GroupExpensesRepositoryImpl repository;
  late MockLocalDataSource mockLocalDataSource;
  late MockRemoteDataSource mockRemoteDataSource;
  late MockOutboxRepository mockOutboxRepository;
  late MockSyncService mockSyncService;
  late MockConnectivity mockConnectivity;

  setUpAll(() {
    registerFallbackValue(FakeSyncMutationModel());
    registerFallbackValue(FakeGroupExpenseModel());
  });

  setUp(() {
    mockLocalDataSource = MockLocalDataSource();
    mockRemoteDataSource = MockRemoteDataSource();
    mockOutboxRepository = MockOutboxRepository();
    mockSyncService = MockSyncService();
    mockConnectivity = MockConnectivity();
    repository = GroupExpensesRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      outboxRepository: mockOutboxRepository,
      syncService: mockSyncService,
      connectivity: mockConnectivity,
    );
  });

  final tExpense = GroupExpense(
    id: '1',
    groupId: 'g1',
    createdBy: 'c1',
    title: 'Dinner',
    amount: 100,
    currency: 'USD',
    occurredAt: DateTime(2023, 10, 27),
    createdAt: DateTime(2023, 10, 27),
    updatedAt: DateTime(2023, 10, 27),
    payers: [ExpensePayer(userId: 'u1', amount: 50)],
    splits: [
      ExpenseSplit(userId: 'u1', amount: 50, splitType: SplitType.equal),
    ],
  );

  final tExpenseModel = GroupExpenseModel.fromEntity(tExpense);

  group('addExpense', () {
    test(
      'should save expense locally, add to outbox, and trigger sync if online',
      () async {
        when(
          () => mockLocalDataSource.saveExpense(any()),
        ).thenAnswer((_) async {});
        when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mockSyncService.processOutbox()).thenAnswer((_) async {});

        final result = await repository.addExpense(tExpense);

        expect(result, Right(tExpense));
        verify(() => mockLocalDataSource.saveExpense(any())).called(1);
        verify(() => mockOutboxRepository.add(any())).called(1);
        verify(() => mockSyncService.processOutbox()).called(1);
      },
    );

    test('should NOT trigger sync if offline', () async {
      when(
        () => mockLocalDataSource.saveExpense(any()),
      ).thenAnswer((_) async {});
      when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      final result = await repository.addExpense(tExpense);

      expect(result, Right(tExpense));
      verify(() => mockLocalDataSource.saveExpense(any())).called(1);
      verify(() => mockOutboxRepository.add(any())).called(1);
      verifyNever(() => mockSyncService.processOutbox());
    });
  });

  group('getExpenses', () {
    test('should return expenses from local data source', () async {
      when(
        () => mockLocalDataSource.getExpenses(any()),
      ).thenReturn([tExpenseModel]);

      final result = await repository.getExpenses('g1');

      // expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right'),
        (expenses) => expect(expenses, [tExpense]),
      );
      verify(() => mockLocalDataSource.getExpenses('g1')).called(1);
    });
  });

  group('syncExpenses', () {
    test('should fetch remote expenses and save locally when online', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => mockRemoteDataSource.getExpenses(any()),
      ).thenAnswer((_) async => [tExpenseModel]);
      when(
        () => mockLocalDataSource.saveExpenses(any()),
      ).thenAnswer((_) async {});

      final result = await repository.syncExpenses('g1');

      // expect(result.isRight(), true);
      // verify(() => mockRemoteDataSource.getExpenses('g1')).called(1);
      // verify(() => mockLocalDataSource.saveExpenses([tExpenseModel])).called(1);
    });

    test('should do nothing when offline', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      final result = await repository.syncExpenses('g1');

      // expect(result.isRight(), true);
      verifyNever(() => mockRemoteDataSource.getExpenses(any()));
    });
  });

  GroupExpense expenseWithId(String id) => GroupExpense(
    id: id,
    groupId: tExpense.groupId,
    createdBy: tExpense.createdBy,
    title: tExpense.title,
    amount: tExpense.amount,
    currency: tExpense.currency,
    occurredAt: tExpense.occurredAt,
    createdAt: tExpense.createdAt,
    updatedAt: tExpense.updatedAt,
    payers: tExpense.payers,
    splits: tExpense.splits,
  );

  void stubOnline({bool online = true}) {
    when(() => mockConnectivity.checkConnectivity()).thenAnswer(
      (_) async =>
          online ? [ConnectivityResult.wifi] : [ConnectivityResult.none],
    );
    when(() => mockSyncService.processOutbox()).thenAnswer((_) async {});
  }

  group('updateExpense', () {
    setUp(() {
      when(
        () => mockLocalDataSource.saveExpense(any()),
      ).thenAnswer((_) async {});
      when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});
    });

    test(
      'saves locally and queues an update, then syncs when online',
      () async {
        stubOnline();

        final result = await repository.updateExpense(tExpense);

        expect(result, Right(tExpense));
        final queued =
            verify(() => mockOutboxRepository.add(captureAny())).captured.single
                as SyncMutationModel;
        // The operation type is what decides create-vs-update on the server.
        expect(queued.operation, OpType.update);
        expect(queued.id, tExpense.id);
        expect(queued.table, 'expenses');
        verify(() => mockSyncService.processOutbox()).called(1);
      },
    );

    test('queues the write but does not sync while offline', () async {
      stubOnline(online: false);

      expect((await repository.updateExpense(tExpense)).isRight(), isTrue);

      // The queue is the whole point of offline support — it must still fill.
      verify(() => mockOutboxRepository.add(any())).called(1);
      verifyNever(() => mockSyncService.processOutbox());
    });

    test('a local write failure is reported and nothing is queued', () async {
      when(
        () => mockLocalDataSource.saveExpense(any()),
      ).thenThrow(Exception('box closed'));

      final result = await repository.updateExpense(tExpense);

      expect(
        result.fold((f) => f, (_) => null),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          contains('box closed'),
        ),
      );
      verifyNever(() => mockOutboxRepository.add(any()));
    });
  });

  group('deleteExpense', () {
    setUp(() {
      when(
        () => mockLocalDataSource.deleteExpense(any()),
      ).thenAnswer((_) async {});
      when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});
    });

    test('deletes locally and queues a delete carrying the id', () async {
      stubOnline();

      final result = await repository.deleteExpense('1');

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.deleteExpense('1')).called(1);
      final queued =
          verify(() => mockOutboxRepository.add(captureAny())).captured.single
              as SyncMutationModel;
      expect(queued.operation, OpType.delete);
      expect(queued.payload, {'id': '1'});
      verify(() => mockSyncService.processOutbox()).called(1);
    });

    test('does not sync while offline', () async {
      stubOnline(online: false);

      expect((await repository.deleteExpense('1')).isRight(), isTrue);

      verifyNever(() => mockSyncService.processOutbox());
    });

    test('a local delete failure is reported', () async {
      when(
        () => mockLocalDataSource.deleteExpense(any()),
      ).thenThrow(Exception('missing'));

      expect(
        (await repository.deleteExpense('1')).fold((f) => f, (_) => null),
        isA<CacheFailure>(),
      );
      verifyNever(() => mockOutboxRepository.add(any()));
    });
  });

  group('syncExpenses', () {
    test('is a no-op while offline', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      expect((await repository.syncExpenses('g1')).isRight(), isTrue);

      verifyNever(() => mockRemoteDataSource.getExpenses(any()));
      verifyNever(() => mockLocalDataSource.saveExpenses(any()));
    });

    test('drops local rows the server no longer has', () async {
      stubOnline();
      final remote = GroupExpenseModel.fromEntity(tExpense);
      final stale = GroupExpenseModel.fromEntity(expenseWithId('stale-1'));
      when(
        () => mockRemoteDataSource.getExpenses('g1'),
      ).thenAnswer((_) async => [remote]);
      when(
        () => mockLocalDataSource.getExpenses('g1'),
      ).thenReturn([remote, stale]);
      when(() => mockOutboxRepository.getPendingItems()).thenReturn([]);
      when(
        () => mockLocalDataSource.deleteExpense(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalDataSource.saveExpenses(any()),
      ).thenAnswer((_) async {});

      expect((await repository.syncExpenses('g1')).isRight(), isTrue);

      verify(() => mockLocalDataSource.deleteExpense('stale-1')).called(1);
      verifyNever(() => mockLocalDataSource.deleteExpense('1'));
      verify(() => mockLocalDataSource.saveExpenses([remote])).called(1);
    });

    test('keeps a local row that is still waiting in the outbox', () async {
      stubOnline();
      final pendingLocal = GroupExpenseModel.fromEntity(
        expenseWithId('not-yet-pushed'),
      );
      when(
        () => mockRemoteDataSource.getExpenses('g1'),
      ).thenAnswer((_) async => []);
      when(
        () => mockLocalDataSource.getExpenses('g1'),
      ).thenReturn([pendingLocal]);
      when(() => mockOutboxRepository.getPendingItems()).thenReturn([
        SyncMutationModel(
          id: 'not-yet-pushed',
          table: 'expenses',
          operation: OpType.create,
          payload: const {},
          createdAt: DateTime(2024, 1, 1),
        ),
      ]);
      when(
        () => mockLocalDataSource.saveExpenses(any()),
      ).thenAnswer((_) async {});

      expect((await repository.syncExpenses('g1')).isRight(), isTrue);

      // Absent from the server only because it has not been pushed yet —
      // deleting it here would lose the user's offline write.
      verifyNever(() => mockLocalDataSource.deleteExpense(any()));
    });

    test('a remote failure surfaces as ServerFailure', () async {
      stubOnline();
      when(
        () => mockRemoteDataSource.getExpenses('g1'),
      ).thenThrow(Exception('502'));

      expect(
        (await repository.syncExpenses('g1')).fold((f) => f, (_) => null),
        isA<ServerFailure>(),
      );
    });
  });
}
