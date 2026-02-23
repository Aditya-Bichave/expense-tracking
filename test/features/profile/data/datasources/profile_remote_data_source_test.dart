import 'dart:async';
import 'package:expense_tracker/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:typed_data';

import 'package:expense_tracker/core/network/supabase_config.dart';
import '../../../../helpers/mocks.dart';

class FakeProfileModel extends Fake implements ProfileModel {}

// Fakes for Chaining and Awaiting
class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final Map<String, dynamic>? singleResult;

  FakePostgrestFilterBuilder({this.singleResult});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    return FakePostgrestTransformBuilderMap(singleResult ?? {});
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

class FakePostgrestFilterBuilderDynamic extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  // Assuming update returns List<Map> even if empty
  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    return this;
  }

  @override
  Future<T> then<T>(
    FutureOr<T> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async {
    return onValue([]);
  }
}

void main() {
  late ProfileRemoteDataSourceImpl dataSource;
  late MockSupabaseClient mockClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockSupabaseStorageClient mockStorageClient;
  late MockStorageFileApi mockStorageFileApi;

  setUpAll(() {
    registerFallbackValue(FakeProfileModel());
    registerFallbackValue(const FileOptions());
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockStorageClient = MockSupabaseStorageClient();
    mockStorageFileApi = MockStorageFileApi();
    dataSource = ProfileRemoteDataSourceImpl(mockClient);

    // Use thenAnswer because SupabaseQueryBuilder implements Future
    when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
    when(() => mockClient.storage).thenReturn(mockStorageClient);
  });

  const tProfileModel = ProfileModel(
    id: '1',
    fullName: 'Test User',
    currency: 'USD',
    timezone: 'UTC',
  );

  final tProfileJson = {
    'id': '1',
    'full_name': 'Test User',
    'currency': 'USD',
    'timezone': 'UTC',
  };

  group('ProfileRemoteDataSource', () {
    test('getProfile should return ProfileModel', () async {
      final fakeBuilder = FakePostgrestFilterBuilder(
        singleResult: tProfileJson,
      );
      // Use thenAnswer because PostgrestFilterBuilder implements Future
      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      final result = await dataSource.getProfile('1');

      expect(result, equals(tProfileModel));
      verify(() => mockClient.from(SupabaseConfig.profilesTable)).called(1);
      verify(() => mockQueryBuilder.select()).called(1);
    });

    test('updateProfile should call update', () async {
      final fakeBuilder = FakePostgrestFilterBuilderDynamic();
      when(() => mockQueryBuilder.update(any())).thenAnswer((_) => fakeBuilder);

      await dataSource.updateProfile(tProfileModel);

      verify(() => mockClient.from(SupabaseConfig.profilesTable)).called(1);
      verify(() => mockQueryBuilder.update(any())).called(1);
    });

    test('uploadAvatar should upload file and return url', () async {
      final tFile = XFile.fromData(Uint8List(0), name: 'avatar.jpg');

      when(() => mockStorageClient.from(any())).thenReturn(mockStorageFileApi);
      when(
        () => mockStorageFileApi.uploadBinary(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).thenAnswer((_) async => '');
      when(
        () => mockStorageFileApi.getPublicUrl(any()),
      ).thenReturn('https://url.com/avatar.jpg');

      final result = await dataSource.uploadAvatar('1', tFile);

      expect(result, 'https://url.com/avatar.jpg');
      verify(
        () => mockStorageClient.from(SupabaseConfig.profileAvatarsBucket),
      ).called(2);
    });
  });
}
