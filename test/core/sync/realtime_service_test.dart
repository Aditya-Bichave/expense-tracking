import 'dart:async';
import 'package:expense_tracker/core/sync/realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class MockPostgresChangePayload extends Mock implements PostgresChangePayload {}

class FakePostgresChangeFilter extends Fake implements PostgresChangeFilter {}

void main() {
  late RealtimeService realtimeService;
  late MockSupabaseClient mockSupabaseClient;
  late MockRealtimeChannel mockRealtimeChannel;
  late StreamController<PostgresChangePayload> changesController;

  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(FakePostgresChangeFilter());
    registerFallbackValue(MockRealtimeChannel());
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockRealtimeChannel = MockRealtimeChannel();
    changesController = StreamController<PostgresChangePayload>.broadcast();

    // Default stubs
    when(
      () => mockSupabaseClient.channel(any()),
    ).thenReturn(mockRealtimeChannel);
    when(
      () => mockRealtimeChannel.onPostgresChanges(
        event: any(named: 'event'),
        schema: any(named: 'schema'),
        table: any(named: 'table'),
        filter: any(named: 'filter'),
        callback: any(named: 'callback'),
      ),
    ).thenReturn(mockRealtimeChannel);

    // Stub subscribe to return self for chaining
    when(() => mockRealtimeChannel.subscribe()).thenReturn(mockRealtimeChannel);

    // Stub removeChannel to return a Future<String>
    when(
      () => mockSupabaseClient.removeChannel(any()),
    ).thenAnswer((_) async => 'ok');
  });

  test(
    'subscribeToGroup subscribes to channel and listens for changes',
    () async {
      realtimeService = RealtimeService(mockSupabaseClient);
      const groupId = 'test_group_id';

      realtimeService.subscribeToGroup(groupId);

      verify(() => mockSupabaseClient.channel('group_$groupId')).called(1);
      verify(
        () => mockRealtimeChannel.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          filter: any(named: 'filter'),
          callback: any(named: 'callback'),
        ),
      ).called(1);
      verify(() => mockRealtimeChannel.subscribe()).called(1);
    },
  );

  test('unsubscribe calls removeChannel', () {
    realtimeService = RealtimeService(mockSupabaseClient);
    // Subscribe first to set _channel
    realtimeService.subscribeToGroup('test_group');

    realtimeService.unsubscribe();

    verify(
      () => mockSupabaseClient.removeChannel(mockRealtimeChannel),
    ).called(1);
  });

  test('changes stream emits payload when callback is triggered', () async {
    // Capture the callback
    Function? capturedCallback;

    when(
      () => mockRealtimeChannel.onPostgresChanges(
        event: any(named: 'event'),
        schema: any(named: 'schema'),
        table: any(named: 'table'),
        filter: any(named: 'filter'),
        callback: any(named: 'callback'),
      ),
    ).thenAnswer((invocation) {
      capturedCallback = invocation.namedArguments[#callback] as Function;
      return mockRealtimeChannel;
    });

    realtimeService = RealtimeService(mockSupabaseClient);
    realtimeService.subscribeToGroup('test_group');

    expect(capturedCallback, isNotNull);

    final mockPayload = MockPostgresChangePayload();

    expectLater(realtimeService.changes, emits(mockPayload));

    // Invoke callback.
    (capturedCallback as dynamic)(mockPayload);
  });
}
