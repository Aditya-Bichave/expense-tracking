import 'package:expense_tracker/core/network/supabase_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage storage;

  SecureLocalStorage(this.storage);

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    try {
      return await storage.containsKey(
        key: SupabaseConfig.supabasePersistSessionKey,
      );
    } catch (e) {
      log.warning('SecureLocalStorage: Error checking access token: $e');
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await storage.read(key: SupabaseConfig.supabasePersistSessionKey);
    } catch (e) {
      log.warning('SecureLocalStorage: Error reading access token: $e');
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await storage.delete(key: SupabaseConfig.supabasePersistSessionKey);
    } catch (e) {
      log.warning('SecureLocalStorage: Error deleting session: $e');
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await storage.write(
        key: SupabaseConfig.supabasePersistSessionKey,
        value: persistSessionString,
      );
    } catch (e) {
      log.warning('SecureLocalStorage: Error persisting session: $e');
    }
  }
}

class SupabaseClientProvider {
  static Future<void> initialize() async {
    try {
      if (!SupabaseConfig.isValid) {
        log.warning(
          'Supabase configuration is invalid. Initializing with placeholder values to prevent crashes.',
        );
        await _initPlaceholder();
        return;
      }

      const secureStorage = FlutterSecureStorage();
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          localStorage: SecureLocalStorage(secureStorage),
        ),
      );
      log.info('Supabase initialized successfully.');
    } catch (e) {
      log.severe('Failed to initialize Supabase: $e');
      // Attempt fallback to prevent app crash on client access
      try {
        await _initPlaceholder();
      } catch (_) {}
    }
  }

  static Future<void> _initPlaceholder() async {
    if (!Supabase.instance.isInitialized) {
      await Supabase.initialize(
        url: 'https://placeholder.supabase.co',
        anonKey: 'placeholder',
        debug: false,
      );
    }
  }

  static SupabaseClient get client {
    if (!Supabase.instance.isInitialized) {
      // Return a temporary client or re-throw.
      // Re-throwing is better than returning null if type is non-nullable.
      // But we can try to init synchronously? No.
      throw Exception(
        'Supabase not initialized. Check logs for startup errors.',
      );
    }
    return Supabase.instance.client;
  }
}
