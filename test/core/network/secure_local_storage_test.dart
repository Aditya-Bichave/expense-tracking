import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/core/network/supabase_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureLocalStorage secureLocalStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureLocalStorage = SecureLocalStorage(mockStorage);
  });

  group('SecureLocalStorage', () {
    const testKey = SupabaseConfig.supabasePersistSessionKey;
    const testValue = 'test_session_token';

    test('hasAccessToken returns true when storage contains key', () async {
      when(
        () => mockStorage.containsKey(key: testKey),
      ).thenAnswer((_) async => true);
      expect(await secureLocalStorage.hasAccessToken(), isTrue);
    });

    test(
      'hasAccessToken returns false when storage throws exception',
      () async {
        when(
          () => mockStorage.containsKey(key: testKey),
        ).thenThrow(Exception('Storage Error'));
        expect(await secureLocalStorage.hasAccessToken(), isFalse);
      },
    );

    test('accessToken returns value when storage read succeeds', () async {
      when(
        () => mockStorage.read(key: testKey),
      ).thenAnswer((_) async => testValue);
      expect(await secureLocalStorage.accessToken(), equals(testValue));
    });

    test('accessToken returns null when storage throws exception', () async {
      when(
        () => mockStorage.read(key: testKey),
      ).thenThrow(Exception('Read Error'));
      expect(await secureLocalStorage.accessToken(), isNull);
    });

    test('removePersistedSession calls delete safely', () async {
      when(() => mockStorage.delete(key: testKey)).thenAnswer((_) async => {});
      await secureLocalStorage.removePersistedSession();
      verify(() => mockStorage.delete(key: testKey)).called(1);
    });

    test('removePersistedSession suppresses exceptions', () async {
      when(
        () => mockStorage.delete(key: testKey),
      ).thenThrow(Exception('Delete Error'));
      await secureLocalStorage.removePersistedSession();
      verify(() => mockStorage.delete(key: testKey)).called(1);
    });

    test('persistSession calls write safely', () async {
      when(
        () => mockStorage.write(key: testKey, value: testValue),
      ).thenAnswer((_) async => {});
      await secureLocalStorage.persistSession(testValue);
      verify(() => mockStorage.write(key: testKey, value: testValue)).called(1);
    });

    test('persistSession suppresses exceptions', () async {
      when(
        () => mockStorage.write(key: testKey, value: testValue),
      ).thenThrow(Exception('Write Error'));
      await secureLocalStorage.persistSession(testValue);
      verify(() => mockStorage.write(key: testKey, value: testValue)).called(1);
    });
  });
}
