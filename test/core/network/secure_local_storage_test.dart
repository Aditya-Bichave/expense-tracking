import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/core/network/secure_local_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SecureLocalStorage secureLocalStorage;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureLocalStorage = SecureLocalStorage(storage: mockStorage);
  });

  group('SecureLocalStorage', () {
    test('initialize does nothing', () async {
      await secureLocalStorage.initialize();
      // No assertion needed, just checking it doesn't throw
    });

    test('hasAccessToken returns true if key exists', () async {
      when(() => mockStorage.containsKey(key: supabasePersistSessionKey))
          .thenAnswer((_) async => true);

      final result = await secureLocalStorage.hasAccessToken();

      expect(result, true);
      verify(() => mockStorage.containsKey(key: supabasePersistSessionKey)).called(1);
    });

    test('accessToken returns value from storage', () async {
      const token = 'test_token';
      when(() => mockStorage.read(key: supabasePersistSessionKey))
          .thenAnswer((_) async => token);

      final result = await secureLocalStorage.accessToken();

      expect(result, token);
      verify(() => mockStorage.read(key: supabasePersistSessionKey)).called(1);
    });

    test('removePersistedSession deletes key', () async {
      when(() => mockStorage.delete(key: supabasePersistSessionKey))
          .thenAnswer((_) async {});

      await secureLocalStorage.removePersistedSession();

      verify(() => mockStorage.delete(key: supabasePersistSessionKey)).called(1);
    });

    test('persistSession writes key', () async {
      const sessionStr = 'session_data';
      when(() => mockStorage.write(key: supabasePersistSessionKey, value: sessionStr))
          .thenAnswer((_) async {});

      await secureLocalStorage.persistSession(sessionStr);

      verify(() => mockStorage.write(key: supabasePersistSessionKey, value: sessionStr)).called(1);
    });
  });
}
