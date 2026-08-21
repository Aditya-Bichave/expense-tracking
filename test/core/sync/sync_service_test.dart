import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockConnectivity extends Mock implements Connectivity {}

class MockBox<T> extends Mock implements Box<T> {}

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockOutboxRepository mockOutboxRepository;
  late MockConnectivity mockConnectivity;
  late MockBox<GroupModel> mockGroupBox;
  late MockBox<GroupMemberModel> mockGroupMemberBox;
  late MockSupabaseStorageClient mockStorageClient;
  late MockStorageFileApi mockStorageFileApi;
  late MockSupabaseQueryBuilder mockQueryBuilder;

  setUpAll(() {
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

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockOutboxRepository = MockOutboxRepository();
    mockConnectivity = MockConnectivity();
    mockGroupBox = MockBox<GroupModel>();
    mockGroupMemberBox = MockBox<GroupMemberModel>();
    mockStorageClient = MockSupabaseStorageClient();
    mockStorageFileApi = MockStorageFileApi();
    mockQueryBuilder = MockSupabaseQueryBuilder();

    when(() => mockSupabaseClient.storage).thenReturn(mockStorageClient);
    when(() => mockStorageClient.from(any())).thenReturn(mockStorageFileApi);
    when(
      () => mockSupabaseClient.from(any()),
    ).thenAnswer((_) => mockQueryBuilder);
  });

  test(
    'SyncService processes pending items with receipt upload (verifies upload call)',
    () async {
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

      final service = SyncService(
        mockSupabaseClient,
        mockOutboxRepository,
        mockConnectivity,
        mockGroupBox,
        mockGroupMemberBox,
      );

      try {
        await service.processOutbox();
      } catch (_) {}

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
    'SyncService handles permanent failure by marking dead-letter state',
    () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => const Stream.empty());

      final item = SyncMutationModel(
        id: 'tx_failed',
        table: 'expenses',
        operation: OpType.create,
        payload: {'amount': 100},
        createdAt: DateTime.now(),
        retryCount: 5,
      );

      when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);
      when(
        () => mockOutboxRepository.markAsFailed(any(), any()),
      ).thenAnswer((_) async {});

      final service = SyncService(
        mockSupabaseClient,
        mockOutboxRepository,
        mockConnectivity,
        mockGroupBox,
        mockGroupMemberBox,
      );

      await service.processOutbox();

      verify(
        () => mockOutboxRepository.markAsFailed(item, 'Max retries exceeded.'),
      ).called(1);
    },
  );
}
