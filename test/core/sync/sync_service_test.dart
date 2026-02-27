import 'dart:async'; // Added import for FutureOr
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

class FakePostgrestFilterBuilder extends Fake implements PostgrestFilterBuilder {
  @override
  Future<T> then<T>(FutureOr<T> Function(dynamic value) onValue, {Function? onError}) {
    return Future.value([]).then((v) => onValue(v));
  }
}

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
    when(() => mockSupabaseClient.from(any())).thenReturn(mockQueryBuilder);

    // Fix: Use thenAnswer for upsert, which returns Future/PostgrestFilterBuilder
    when(() => mockQueryBuilder.upsert(any())).thenAnswer((_) => FakePostgrestFilterBuilder());
  });

  test('SyncService processes pending items with receipt upload', () async {
    // Arrange
    when(() => mockConnectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(() => mockConnectivity.onConnectivityChanged).thenAnswer((_) => const Stream.empty());

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
    when(() => mockOutboxRepository.markAsSent(any())).thenAnswer((_) async {});

    when(() => mockStorageFileApi.upload(any(), any(), fileOptions: any(named: 'fileOptions'))).thenAnswer((_) async => '');
    when(() => mockStorageFileApi.getPublicUrl(any())).thenReturn('https://supabase.co/receipt.jpg');

    final service = SyncService(
      mockSupabaseClient,
      mockOutboxRepository,
      mockConnectivity,
      mockGroupBox,
      mockGroupMemberBox,
    );

    // Act
    await service.processOutbox();

    // Assert
    // Verify upload was called
    verify(() => mockStorageFileApi.upload(
      any(that: contains('tx1.jpg')),
      any(),
      fileOptions: any(named: 'fileOptions'),
    )).called(1);

    // Verify upsert called with updated payload
    verify(() => mockQueryBuilder.upsert(
      any(that: isA<Map<String, dynamic>>()
        .having((m) => m['p_receipt_url'], 'receipt url', 'https://supabase.co/receipt.jpg')
        .having((m) => m.containsKey('x_local_receipt_path'), 'no local path', false)
      ),
    )).called(1);
  });
}
