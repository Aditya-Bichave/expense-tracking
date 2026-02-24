import 'dart:convert';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SecureStorageService service;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(mockStorage);
  });

  group('SecureStorageService', () {
    const hiveKeyKey = 'hive_encryption_key';
    const appPinKey = 'app_pin';
    const biometricEnabledKey = 'biometric_enabled';

    group('getHiveKey', () {
      test('returns existing key if present', () async {
        final key = List<int>.filled(32, 1);
        final encodedKey = base64UrlEncode(key);
        when(
          () => mockStorage.read(key: hiveKeyKey),
        ).thenAnswer((_) async => encodedKey);

        final result = await service.getHiveKey();
        expect(result, key);
      });

      test('generates and saves new key if missing', () async {
        when(
          () => mockStorage.read(key: hiveKeyKey),
        ).thenAnswer((_) async => null);
        when(
          () => mockStorage.write(
            key: hiveKeyKey,
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        final result = await service.getHiveKey();

        expect(result.length, 32); // Hive keys are 32 bytes
        verify(
          () => mockStorage.write(
            key: hiveKeyKey,
            value: any(named: 'value'),
          ),
        ).called(1);
      });

      test('regenerates key if corrupted', () async {
        when(
          () => mockStorage.read(key: hiveKeyKey),
        ).thenAnswer((_) async => '!!corrupt!!');
        when(
          () => mockStorage.write(
            key: hiveKeyKey,
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        final result = await service.getHiveKey();

        expect(result.length, 32);
        verify(
          () => mockStorage.write(
            key: hiveKeyKey,
            value: any(named: 'value'),
          ),
        ).called(1);
      });
    });

    group('PIN', () {
      test('savePin writes to storage', () async {
        when(
          () => mockStorage.write(key: appPinKey, value: '1234'),
        ).thenAnswer((_) async {});
        await service.savePin('1234');
        verify(
          () => mockStorage.write(key: appPinKey, value: '1234'),
        ).called(1);
      });

      test('getPin reads from storage', () async {
        when(
          () => mockStorage.read(key: appPinKey),
        ).thenAnswer((_) async => '1234');
        expect(await service.getPin(), '1234');
      });

      test('deletePin deletes from storage', () async {
        when(() => mockStorage.delete(key: appPinKey)).thenAnswer((_) async {});
        await service.deletePin();
        verify(() => mockStorage.delete(key: appPinKey)).called(1);
      });
    });

    group('Biometrics', () {
      test('setBiometricEnabled writes true', () async {
        when(
          () => mockStorage.write(key: biometricEnabledKey, value: 'true'),
        ).thenAnswer((_) async {});
        await service.setBiometricEnabled(true);
        verify(
          () => mockStorage.write(key: biometricEnabledKey, value: 'true'),
        ).called(1);
      });

      test('isBiometricEnabled returns true if stored value is true', () async {
        when(
          () => mockStorage.read(key: biometricEnabledKey),
        ).thenAnswer((_) async => 'true');
        expect(await service.isBiometricEnabled(), true);
      });

      test(
        'isBiometricEnabled returns false if stored value is false or null',
        () async {
          when(
            () => mockStorage.read(key: biometricEnabledKey),
          ).thenAnswer((_) async => 'false');
          expect(await service.isBiometricEnabled(), false);

          when(
            () => mockStorage.read(key: biometricEnabledKey),
          ).thenAnswer((_) async => null);
          expect(await service.isBiometricEnabled(), false);
        },
      );
    });

    test('clearAll deletes all', () async {
      when(() => mockStorage.deleteAll()).thenAnswer((_) async {});
      await service.clearAll();
      verify(() => mockStorage.deleteAll()).called(1);
    });
  });
}
