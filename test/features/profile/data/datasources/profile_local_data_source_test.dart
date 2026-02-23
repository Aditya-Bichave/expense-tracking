import 'package:expense_tracker/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<ProfileModel> {}

class FakeProfileModel extends Fake implements ProfileModel {}

void main() {
  late ProfileLocalDataSourceImpl dataSource;
  late MockBox mockBox;

  setUpAll(() {
    registerFallbackValue(FakeProfileModel());
  });

  setUp(() {
    mockBox = MockBox();
    dataSource = ProfileLocalDataSourceImpl(mockBox);
  });

  const tProfileModel = ProfileModel(
    id: '1',
    fullName: 'Test User',
    email: 'test@example.com',
    currency: 'USD',
    timezone: 'UTC',
  );

  group('ProfileLocalDataSource', () {
    test('should cache ProfileModel', () async {
      // arrange
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      // act
      await dataSource.cacheProfile(tProfileModel);
      // assert
      verify(() => mockBox.put('current_profile', tProfileModel)).called(1);
    });

    test(
      'should return ProfileModel from Hive when there is one in the cache',
      () async {
        // arrange
        when(() => mockBox.get(any())).thenReturn(tProfileModel);
        // act
        final result = await dataSource.getLastProfile();
        // assert
        verify(() => mockBox.get('current_profile'));
        expect(result, equals(tProfileModel));
      },
    );

    test('should return null when there is no cached value', () async {
      // arrange
      when(() => mockBox.get(any())).thenReturn(null);
      // act
      final result = await dataSource.getLastProfile();
      // assert
      verify(() => mockBox.get('current_profile'));
      expect(result, isNull);
    });

    test('should clear cached profile', () async {
      // arrange
      when(() => mockBox.delete(any())).thenAnswer((_) async {});
      // act
      await dataSource.clearProfile();
      // assert
      verify(() => mockBox.delete('current_profile'));
    });
  });
}
