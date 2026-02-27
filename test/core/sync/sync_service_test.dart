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

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockOutboxRepository mockOutboxRepository;
  late MockConnectivity mockConnectivity;
  late MockBox<GroupModel> mockGroupBox;
  late MockBox<GroupMemberModel> mockGroupMemberBox;
  late MockSupabaseStorageClient mockStorageClient;
  late MockStorageFileApi mockStorageFileApi;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockPostgrestFilterBuilder;

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
    mockPostgrestFilterBuilder = MockPostgrestFilterBuilder();

    when(() => mockSupabaseClient.storage).thenReturn(mockStorageClient);
    when(() => mockStorageClient.from(any())).thenReturn(mockStorageFileApi);

    // Use thenAnswer synchronously. Returns SupabaseQueryBuilder (which might be a Future in Dart type system view if it implements it, but we return the object directly).
    when(
      () => mockSupabaseClient.from(any()),
    ).thenAnswer((_) => mockQueryBuilder);

    // Mock the Future behavior of the builder (for await)
    // We return a Future that completes with an empty list
    when(
      () => mockPostgrestFilterBuilder.then(
        any(),
        onError: any(named: 'onError'),
      ),
    ).thenAnswer((invocation) async {
      final onValue =
          invocation.positionalArguments[0]
              as dynamic Function(List<Map<String, dynamic>>);
      return onValue([]);
    });

    // Use thenAnswer synchronously. Returns PostgrestFilterBuilder (which implements Future).
    when(
      () => mockQueryBuilder.upsert(any()),
    ).thenAnswer((_) => mockPostgrestFilterBuilder);
  });

  test('SyncService processes pending items with receipt upload', () async {
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
    when(() => mockOutboxRepository.markAsSent(any())).thenAnswer((_) async {});

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

    // Act
    await service.processOutbox();

    // Assert
    // Verify upload was called
    verify(
      () => mockStorageFileApi.upload(
        any(that: contains('tx1.jpg')),
        any(),
        fileOptions: any(named: 'fileOptions'),
      ),
    ).called(1);

    // Verify upsert called with updated payload
    // Using dynamic cast to verify calling a method on the mock is safer for matchers
    verify(
      () => mockQueryBuilder.upsert(
        any(
          that: isA<Map<String, dynamic>>()
              .having(
                (m) => m['p_receipt_url'],
                'receipt url',
                'https://supabase.co/receipt.jpg',
              )
              .having(
                (m) => m.containsKey('x_local_receipt_path'),
                'no local path',
                false,
              ),
        ),
      ),
    ).called(1);
  });
}
