import 'dart:async';
import 'package:expense_tracker/features/groups/data/datasources/groups_remote_data_source.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class FakeGroupModel extends Fake implements GroupModel {}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> _result;
  final Map<String, dynamic>? _singleResult;

  FakePostgrestFilterBuilder(this._result, {Map<String, dynamic>? singleResult})
    : _singleResult = singleResult;

  @override
  Future<T> then<T>(
    FutureOr<T> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async {
    return onValue(_result);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    return FakePostgrestTransformBuilderMap(_singleResult ?? {});
  }
}

class FakePostgrestTransformBuilderMap extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>> {
  final Map<String, dynamic> _result;
  FakePostgrestTransformBuilderMap(this._result);

  @override
  Future<T> then<T>(
    FutureOr<T> Function(Map<String, dynamic> value) onValue, {
    Function? onError,
  }) async {
    return onValue(_result);
  }
}

void main() {
  late GroupsRemoteDataSourceImpl dataSource;
  late MockSupabaseClient mockClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockFunctionsClient mockFunctionsClient;

  setUpAll(() {
    registerFallbackValue(FakeGroupModel());
    registerFallbackValue(HttpMethod.post);
    registerFallbackValue(<String, String>{});
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFunctionsClient = MockFunctionsClient();
    dataSource = GroupsRemoteDataSourceImpl(mockClient);

    when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
    when(() => mockClient.functions).thenReturn(mockFunctionsClient);
  });

  final tDate = DateTime(2023, 1, 1);
  final tGroupModel = GroupModel(
    id: '1',
    name: 'Test Group',
    createdBy: 'user1',
    createdAt: tDate,
    updatedAt: tDate,
    typeValue: 'custom',
    currency: 'USD',
  );

  final tGroupJson = {
    'id': '1',
    'name': 'Test Group',
    'created_by': 'user1',
    'created_at': tDate.toIso8601String(),
    'updated_at': tDate.toIso8601String(),
    'type': 'custom',
    'currency': 'USD',
  };

  group('GroupsRemoteDataSource', () {
    test('createGroup should return GroupModel', () async {
      final fakeBuilder = FakePostgrestFilterBuilder(
        [],
        singleResult: tGroupJson,
      );

      when(() => mockQueryBuilder.insert(any())).thenAnswer((_) => fakeBuilder);

      final result = await dataSource.createGroup(tGroupModel);

      expect(result.id, tGroupModel.id);
      verify(() => mockClient.from('groups')).called(1);
      verify(() => mockQueryBuilder.insert(any())).called(1);
    });

    test('getGroups should return list of groups', () async {
      final fakeBuilder = FakePostgrestFilterBuilder([tGroupJson]);
      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      final result = await dataSource.getGroups();

      expect(result.length, 1);
      expect(result.first.id, tGroupModel.id);
    });

    test('createInvite should return invite url', () async {
      when(
        () => mockFunctionsClient.invoke(
          'create-invite',
          headers: any(named: 'headers'),
          body: any(named: 'body'),
          method: any(named: 'method'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(data: {'invite_url': 'url'}, status: 200),
      );

      final result = await dataSource.createInvite('1');
      expect(result, 'url');
    });

    test('acceptInvite should return response data', () async {
      when(
        () => mockFunctionsClient.invoke(
          'join_group_via_invite',
          headers: any(named: 'headers'),
          body: any(named: 'body'),
          method: any(named: 'method'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(data: {'success': true}, status: 200),
      );

      final result = await dataSource.acceptInvite('token');
      expect(result['success'], true);
    });
  });
}
