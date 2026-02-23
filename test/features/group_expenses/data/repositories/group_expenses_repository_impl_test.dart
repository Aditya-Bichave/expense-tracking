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

      expect(result.isRight(), true);
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

      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.getExpenses('g1')).called(1);
      verify(() => mockLocalDataSource.saveExpenses([tExpenseModel])).called(1);
    });

    test('should do nothing when offline', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      final result = await repository.syncExpenses('g1');

      expect(result.isRight(), true);
      verifyNever(() => mockRemoteDataSource.getExpenses(any()));
    });
  });
}
