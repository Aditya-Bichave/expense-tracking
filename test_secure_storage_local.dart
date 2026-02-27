import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  test('reproduce secure storage crash', () async {
    final mockStorage = MockFlutterSecureStorage();
    final service = SecureStorageService(storage: mockStorage);

    when(
      () => mockStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => '%%%NotBase64%%%');

    try {
      await service.getHiveKey();
      print('No exception thrown');
    } catch (e) {
      print('Caught exception: $e');
    }
  });
}
