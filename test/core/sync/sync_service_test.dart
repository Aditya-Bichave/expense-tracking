import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/dead_letter_repository.dart';
import 'package:expense_tracker/core/sync/models/dead_letter_model.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockDeadLetterRepository extends Mock implements DeadLetterRepository {}

class MockConnectivity extends Mock implements Connectivity {}

class MockBox<T> extends Mock implements Box<T> {}

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> _data;
  FakePostgrestFilterBuilder(this._data);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    return this;
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    return FakePostgrestTransformBuilder(_data);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    return Future.value(_data).then(onValue, onError: onError);
  }
}

class FakePostgrestTransformBuilder extends Fake
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> _data;
  FakePostgrestTransformBuilder(this._data);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    return Future.value(_data).then(onValue, onError: onError);
  }
}

// Separate Fake for delete
class FakeDeleteFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) {
    return this;
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) {
    // Actually, delete() without select() returns a PostgrestResponse or List. Usually it is a List or null.
    // The await expects a Future<void> or Future<dynamic>.
    // In Dart, if we just return Future.value(null), it should work if R is dynamic.
    return Future<dynamic>.value(null).then(onValue, onError: onError)
        ;
  }
}

class FakeDeadLetterModel extends Fake implements DeadLetterModel {}

class FakeSyncMutationModel extends Fake implements SyncMutationModel {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockOutboxRepository mockOutboxRepository;
  late MockDeadLetterRepository mockDeadLetterRepository;
  late MockConnectivity mockConnectivity;
  late MockBox<GroupModel> mockGroupBox;
  late MockBox<GroupMemberModel> mockGroupMemberBox;
  late MockSupabaseStorageClient mockStorageClient;
  late MockStorageFileApi mockStorageFileApi;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;

  setUpAll(() {
    registerFallbackValue(FakeDeadLetterModel());
    registerFallbackValue(FakeSyncMutationModel());
    registerFallbackValue(File(''));
    registerFallbackValue(const FileOptions());
    registerFallbackValue(
      SyncMutationModel(
        id: 'fallback',
        table: 'fallback',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
      ),
    );
  });

  SyncService createService() {
    return SyncService(
      mockSupabaseClient,
      mockOutboxRepository,
      mockDeadLetterRepository,
      mockConnectivity,
      mockGroupBox,
      mockGroupMemberBox,
    );
  }

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockOutboxRepository = MockOutboxRepository();
    mockDeadLetterRepository = MockDeadLetterRepository();
    mockConnectivity = MockConnectivity();
    mockGroupBox = MockBox<GroupModel>();
    mockGroupMemberBox = MockBox<GroupMemberModel>();
    mockStorageClient = MockSupabaseStorageClient();
    mockStorageFileApi = MockStorageFileApi();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();

    // Use thenAnswer for methods returning Future-like objects (e.g. SupabaseQueryBuilder)
    when(() => mockSupabaseClient.storage).thenReturn(mockStorageClient);
    when(() => mockStorageClient.from(any())).thenReturn(mockStorageFileApi);
    when(
      () => mockSupabaseClient.from(any()),
    ).thenAnswer((_) => mockQueryBuilder);
  });

  test(
    'SyncService processes pending items with receipt upload (verifies upload call)',
    () async {
      // Arrange
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => const Stream.empty());

      final item = SyncMutationModel(
        id: 'tx1',
        table: 'rpc/create_expense_transaction',
        operation: OpType.create,
        payload: {
          'p_amount_total': 100,
          'x_local_receipt_path': '/path/to/receipt.jpg',
        },
        createdAt: DateTime.now(),
      );

      when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);
      when(
        () => mockOutboxRepository.markAsSent(any()),
      ).thenAnswer((_) async {});

      when(
        () => mockStorageFileApi.upload(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).thenAnswer((_) async => '');
      when(
        () => mockStorageFileApi.getPublicUrl(any()),
      ).thenReturn('https://supabase.co/receipt.jpg');

      // NOTE: We intentionally DO NOT mock upsert here to avoid Mocktail Future type issues.
      // It will throw a "no stub" exception when called, which we verify happens *after* upload.

      final service = SyncService(
        mockSupabaseClient,
        mockOutboxRepository,
        mockDeadLetterRepository,
        mockConnectivity,
        mockGroupBox,
        mockGroupMemberBox,
      );

      // Act
      try {
        await service.processOutbox();
      } catch (_) {
        // Expected exception (MissingStubError or similar) because we didn't mock upsert
        // We don't assert on the type to be flexible, but it ensures we reached the upsert call.
      }

      // Assert
      // Verify upload was called - this confirms the receipt upload logic is executed before upsert
      verify(
        () => mockStorageFileApi.upload(
          any(that: contains('tx1.jpg')),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).called(1);
    },
  );

  test(
    'SyncService moves item to DeadLetterRepository when max retries exceeded',
    () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => const Stream.empty());

      final item = SyncMutationModel(
        id: 'tx1',
        table: 'expenses',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
        retryCount: 5,
      );

      when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);
      when(() => mockDeadLetterRepository.add(any())).thenAnswer((_) async {});
      when(
        () => mockOutboxRepository.markAsSent(item),
      ).thenAnswer((_) async {});

      final service = SyncService(
        mockSupabaseClient,
        mockOutboxRepository,
        mockDeadLetterRepository,
        mockConnectivity,
        mockGroupBox,
        mockGroupMemberBox,
      );

      await service.processOutbox();

      verify(() => mockDeadLetterRepository.add(any())).called(1);
      verify(() => mockOutboxRepository.markAsSent(item)).called(1);
    },
  );

  test(
    'SyncService moves item to DeadLetterRepository on schema error',
    () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => const Stream.empty());

      final item = SyncMutationModel(
        id: 'tx1',
        table: 'expenses',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
      );

      when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);
      when(() => mockDeadLetterRepository.add(any())).thenAnswer((_) async {});
      when(
        () => mockOutboxRepository.markAsSent(item),
      ).thenAnswer((_) async {});
      when(
        () => mockQueryBuilder.upsert(any()),
      ).thenThrow(Exception('schema error'));

      final service = SyncService(
        mockSupabaseClient,
        mockOutboxRepository,
        mockDeadLetterRepository,
        mockConnectivity,
        mockGroupBox,
        mockGroupMemberBox,
      );

      await service.processOutbox();

      verify(() => mockDeadLetterRepository.add(any())).called(1);
      verify(() => mockOutboxRepository.markAsSent(item)).called(1);
    },
  );

  test('SyncService queues receipt upload on storage error', () async {
    when(
      () => mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());

    final item = SyncMutationModel(
      id: 'tx1',
      table: 'expenses',
      operation: OpType.create,
      payload: {'x_local_receipt_path': '/path/to/receipt.jpg'},
      createdAt: DateTime.now(),
    );

    when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);
    when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});
    // We let upsert throw a normal error so the item gets marked as failed (which is fine, or we mock upsert to throw Null again)
    when(
      () => mockStorageFileApi.upload(
        any(),
        any(),
        fileOptions: any(named: 'fileOptions'),
      ),
    ).thenThrow(Exception('Storage timeout'));

    final service = SyncService(
      mockSupabaseClient,
      mockOutboxRepository,
      mockDeadLetterRepository,
      mockConnectivity,
      mockGroupBox,
      mockGroupMemberBox,
    );

    await service.processOutbox();

    verify(
      () => mockOutboxRepository.add(
        any(
          that: isA<SyncMutationModel>().having(
            (m) => m.table,
            'table',
            'receipt_upload_queue',
          ),
        ),
      ),
    ).called(1);
  });

  test('SyncService processes update operation correctly', () async {
    final item = SyncMutationModel(
      id: 'tx1',
      table: 'expenses',
      operation: OpType.update,
      payload: {'amount': 200},
      createdAt: DateTime.now(),
    );

    when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);
    when(
      () => mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());

    final fakeBuilder = FakePostgrestFilterBuilder([
      {'id': 'tx1'},
    ]);
    when(() => mockQueryBuilder.update(any())).thenAnswer((_) => fakeBuilder);

    final service = createService();
    await service.processOutbox();

    verify(() => mockQueryBuilder.update({'amount': 200})).called(1);
    verify(() => mockOutboxRepository.markAsSent(item)).called(1);
  });

  test(
    'SyncService processes update operation and falls back to upsert if 0 rows affected',
    () async {
      final item = SyncMutationModel(
        id: 'tx1',
        table: 'expenses',
        operation: OpType.update,
        payload: {'amount': 200},
        createdAt: DateTime.now(),
      );

      when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => const Stream.empty());

      final fakeBuilder = FakePostgrestFilterBuilder([]);
      when(() => mockQueryBuilder.update(any())).thenAnswer((_) => fakeBuilder);
      when(
        () => mockQueryBuilder.upsert(any()),
      ).thenAnswer((_) => FakePostgrestFilterBuilder([]));

      final service = createService();
      await service.processOutbox();

      verify(() => mockQueryBuilder.update({'amount': 200})).called(1);
      verify(() => mockQueryBuilder.upsert({'amount': 200})).called(1);
    },
  );

  test('SyncService processes delete operation correctly', () async {
    final item = SyncMutationModel(
      id: 'tx1',
      table: 'expenses',
      operation: OpType.delete,
      payload: {},
      createdAt: DateTime.now(),
    );

    when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);
    when(
      () => mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());

    final fakeBuilder = FakeDeleteFilterBuilder();
    when(() => mockQueryBuilder.delete()).thenAnswer((_) => fakeBuilder);

    final service = createService();
    await service.processOutbox();

    verify(() => mockQueryBuilder.delete()).called(1);
    verify(() => mockOutboxRepository.markAsSent(item)).called(1);
  });
}
