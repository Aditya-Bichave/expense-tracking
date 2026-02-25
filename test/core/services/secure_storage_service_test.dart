import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'dart:convert';
import 'dart:typed_data';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SecureStorageService service;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(storage: mockStorage);
  });

  group('getHiveKey', () {
    test('should generate and save new key if none exists', () async {
      // Stub read to return null (no key)
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      // Stub write to return void
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final key = await service.getHiveKey();

      expect(key, isA<List<int>>());
      expect(key.length, 32); // Hive keys are 32 bytes
      verify(
        () => mockStorage.write(
          key: 'hive_encryption_key',
          value: any(named: 'value'),
        ),
      ).called(1);
    });

    test('should return existing key if valid', () async {
      final key = List<int>.generate(32, (i) => i);
      final keyString = base64UrlEncode(key);

      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => keyString);

      final result = await service.getHiveKey();

      expect(result, equals(key));
      verifyNever(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });

    test(
      'should THROW HiveKeyCorruptionException if key is corrupted',
      () async {
        // "Corrupted" means not valid base64 or empty in a way decode fails
        when(
          () => mockStorage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => '%%%NotBase64%%%');

        await expectLater(
          service.getHiveKey(),
          throwsA(isA<HiveKeyCorruptionException>()),
        );

        // Verify we DID NOT try to write a new key (overwriting the old one)
        verifyNever(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        );
      },
    );
  });
}
