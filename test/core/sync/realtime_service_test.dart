import 'dart:async';
import 'package:expense_tracker/core/sync/realtime_service.dart';
import 'package:expense_tracker/core/sync/realtime_service.dart';
import 'package:expense_tracker/features/group_expenses/data/datasources/group_expenses_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class MockGroupsLocalDataSource extends Mock implements GroupsLocalDataSource {}

class MockGroupExpensesLocalDataSource extends Mock
    implements GroupExpensesLocalDataSource {}

void main() {
  late RealtimeService service;
  late MockSupabaseClient mockClient;
  late MockRealtimeChannel mockChannel;
  late MockGroupsLocalDataSource mockGroupsDataSource;
  late MockGroupExpensesLocalDataSource mockExpensesDataSource;

  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(MockRealtimeChannel());
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockChannel = MockRealtimeChannel();
    mockGroupsDataSource = MockGroupsLocalDataSource();
    mockExpensesDataSource = MockGroupExpensesLocalDataSource();
    service = RealtimeService(
      mockClient,
      mockGroupsDataSource,
      mockExpensesDataSource,
    );

    when(() => mockClient.channel(any())).thenReturn(mockChannel);
    when(
      () => mockChannel.onPostgresChanges(
        event: any(named: 'event'),
        schema: any(named: 'schema'),
        table: any(named: 'table'),
        callback: any(named: 'callback'),
      ),
    ).thenReturn(mockChannel);

    when(() => mockChannel.subscribe()).thenReturn(mockChannel);
    when(() => mockClient.removeChannel(any())).thenAnswer((_) async => 'ok');
  });

  test('subscribe should initialize subscription', () {
    service.subscribe();

    verify(() => mockClient.channel('public:all')).called(1);
    verify(() => mockChannel.subscribe()).called(1);
  });

  test('unsubscribe should remove channel', () {
    service.subscribe();
    service.unsubscribe();

    verify(() => mockClient.removeChannel(mockChannel)).called(1);
  });
}
