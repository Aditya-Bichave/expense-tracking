import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/core/network/supabase_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SecureLocalStorage localStorage;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    localStorage = SecureLocalStorage(mockStorage);
  });

  group('SecureLocalStorage', () {
    test('hasAccessToken returns true when key exists', () async {
      when(
        () => mockStorage.containsKey(
          key: SupabaseConfig.supabasePersistSessionKey,
        ),
      ).thenAnswer((_) async => true);
      expect(await localStorage.hasAccessToken(), true);
    });

    test('accessToken returns token when it exists', () async {
      when(
        () => mockStorage.read(key: SupabaseConfig.supabasePersistSessionKey),
      ).thenAnswer((_) async => 'token');
      expect(await localStorage.accessToken(), 'token');
    });

    test('removePersistedSession deletes key', () async {
      when(
        () => mockStorage.delete(key: SupabaseConfig.supabasePersistSessionKey),
      ).thenAnswer((_) async {});
      await localStorage.removePersistedSession();
      verify(
        () => mockStorage.delete(key: SupabaseConfig.supabasePersistSessionKey),
      ).called(1);
    });

    test('persistSession writes key', () async {
      when(
        () => mockStorage.write(
          key: SupabaseConfig.supabasePersistSessionKey,
          value: 'session',
        ),
      ).thenAnswer((_) async {});
      await localStorage.persistSession('session');
      verify(
        () => mockStorage.write(
          key: SupabaseConfig.supabasePersistSessionKey,
          value: 'session',
        ),
      ).called(1);
    });
  });
}
