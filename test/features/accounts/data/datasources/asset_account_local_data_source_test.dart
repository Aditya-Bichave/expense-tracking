import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<AssetAccountModel> {}

class FakeAssetAccountModel extends Fake implements AssetAccountModel {}

void main() {
  late HiveAssetAccountLocalDataSource dataSource;
  late MockBox mockBox;

  setUpAll(() {
    registerFallbackValue(FakeAssetAccountModel());
  });

  setUp(() {
    mockBox = MockBox();
    dataSource = HiveAssetAccountLocalDataSource(mockBox);
  });

  final tAssetAccountModel = AssetAccountModel(
    id: '1',
    name: 'Test Account',
    typeIndex: 0,
    initialBalance: 100.0,
  );

  group('getAssetAccounts', () {
    test('should return list of AssetAccountModel from Hive', () async {
      when(() => mockBox.values).thenReturn([tAssetAccountModel]);

      final result = await dataSource.getAssetAccounts();

      expect(result, [tAssetAccountModel]);
      verify(() => mockBox.values);
    });

    test('should throw CacheFailure when Hive throws an exception', () async {
      when(() => mockBox.values).thenThrow(Exception());

      final call = dataSource.getAssetAccounts;

      expect(() => call(), throwsA(isA<CacheFailure>()));
    });
  });

  group('addAssetAccount', () {
    test('should add AssetAccountModel to Hive', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async => {});

      final result = await dataSource.addAssetAccount(tAssetAccountModel);

      expect(result, tAssetAccountModel);
      verify(() => mockBox.put(tAssetAccountModel.id, tAssetAccountModel));
    });

    test('should throw CacheFailure when Hive throws an exception', () async {
      when(() => mockBox.put(any(), any())).thenThrow(Exception());

      final call = dataSource.addAssetAccount;

      expect(() => call(tAssetAccountModel), throwsA(isA<CacheFailure>()));
    });
  });

  group('deleteAssetAccount', () {
    test('should delete AssetAccountModel from Hive', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async => {});

      await dataSource.deleteAssetAccount('1');

      verify(() => mockBox.delete('1'));
    });

    test('should throw CacheFailure when Hive throws an exception', () async {
      when(() => mockBox.delete(any())).thenThrow(Exception());

      final call = dataSource.deleteAssetAccount;

      expect(() => call('1'), throwsA(isA<CacheFailure>()));
    });
  });

  group('updateAssetAccount', () {
    test('should update AssetAccountModel in Hive', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async => {});

      final result = await dataSource.updateAssetAccount(tAssetAccountModel);

      expect(result, tAssetAccountModel);
      verify(() => mockBox.put(tAssetAccountModel.id, tAssetAccountModel));
    });

    test('should throw CacheFailure when Hive throws an exception', () async {
      when(() => mockBox.put(any(), any())).thenThrow(Exception());

      final call = dataSource.updateAssetAccount;

      expect(() => call(tAssetAccountModel), throwsA(isA<CacheFailure>()));
    });
  });
}
