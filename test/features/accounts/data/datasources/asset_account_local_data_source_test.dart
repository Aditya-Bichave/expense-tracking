import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/core/error/failure.dart';

import 'package:expense_tracker/core/utils/logger.dart';
import 'package:simple_logger/simple_logger.dart';

class MockBox extends Mock implements Box<AssetAccountModel> {}

class FakeAssetAccountModel extends Fake implements AssetAccountModel {}

void main() {
  late HiveAssetAccountLocalDataSource dataSource;
  late MockBox mockBox;

  setUpAll(() {
    registerFallbackValue(FakeAssetAccountModel());
    log.setLevel(Level.OFF);
  });

  setUp(() {
    mockBox = MockBox();
    dataSource = HiveAssetAccountLocalDataSource(mockBox);
  });

  group('HiveAssetAccountLocalDataSource', () {
    final tAccount = AssetAccountModel(
      id: '1',
      name: 'Test Account',
      typeIndex: 0,
      initialBalance: 100.0,
    );

    group('addAssetAccount', () {
      test('should add account to box and return it', () async {
        // Arrange
        when(() => mockBox.put(any(), any())).thenAnswer((_) async => {});

        // Act
        final result = await dataSource.addAssetAccount(tAccount);

        // Assert
        verify(() => mockBox.put(tAccount.id, tAccount)).called(1);
        expect(result, equals(tAccount));
      });

      test('should throw CacheFailure when box operation fails', () async {
        // Arrange
        when(
          () => mockBox.put(any(), any()),
        ).thenThrow(Exception('Hive Error'));

        // Act & Assert
        expect(
          () => dataSource.addAssetAccount(tAccount),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('getAssetAccounts', () {
      test('should return list of accounts from box', () async {
        // Arrange
        final List<AssetAccountModel> tAccounts = [tAccount];
        when(() => mockBox.values).thenReturn(tAccounts);

        // Act
        final result = await dataSource.getAssetAccounts();

        // Assert
        expect(result, equals(tAccounts));
      });

      test('should throw CacheFailure when box access fails', () async {
        // Arrange
        when(() => mockBox.values).thenThrow(Exception('Hive Error'));

        // Act & Assert
        expect(
          () => dataSource.getAssetAccounts(),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('updateAssetAccount', () {
      test('should update account in box and return it', () async {
        // Arrange
        when(() => mockBox.put(any(), any())).thenAnswer((_) async => {});

        // Act
        final result = await dataSource.updateAssetAccount(tAccount);

        // Assert
        verify(() => mockBox.put(tAccount.id, tAccount)).called(1);
        expect(result, equals(tAccount));
      });

      test('should throw CacheFailure when update fails', () async {
        // Arrange
        when(
          () => mockBox.put(any(), any()),
        ).thenThrow(Exception('Hive Error'));

        // Act & Assert
        expect(
          () => dataSource.updateAssetAccount(tAccount),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('deleteAssetAccount', () {
      test('should delete account from box', () async {
        // Arrange
        when(() => mockBox.delete(any())).thenAnswer((_) async => {});

        // Act
        await dataSource.deleteAssetAccount(tAccount.id);

        // Assert
        verify(() => mockBox.delete(tAccount.id)).called(1);
      });

      test('should throw CacheFailure when delete fails', () async {
        // Arrange
        when(() => mockBox.delete(any())).thenThrow(Exception('Hive Error'));

        // Act & Assert
        expect(
          () => dataSource.deleteAssetAccount(tAccount.id),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('clearAll', () {
      test('should clear all accounts from box', () async {
        // Arrange
        when(() => mockBox.clear()).thenAnswer((_) async => 0);

        // Act
        await dataSource.clearAll();

        // Assert
        verify(() => mockBox.clear()).called(1);
      });

      test('should throw CacheFailure when clear fails', () async {
        // Arrange
        when(() => mockBox.clear()).thenThrow(Exception('Hive Error'));

        // Act & Assert
        expect(() => dataSource.clearAll(), throwsA(isA<CacheFailure>()));
      });
    });
  });
}
