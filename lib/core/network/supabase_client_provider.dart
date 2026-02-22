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
    return await storage.containsKey(key: SupabaseConfig.supabasePersistSessionKey);
  }

  @override
  Future<String?> accessToken() async {
    return await storage.read(key: SupabaseConfig.supabasePersistSessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    await storage.delete(key: SupabaseConfig.supabasePersistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await storage.write(key: SupabaseConfig.supabasePersistSessionKey, value: persistSessionString);
  }
}

class SupabaseClientProvider {
  static Future<void> initialize() async {
    try {
      if (!SupabaseConfig.isValid) {
        log.warning(
          'Supabase configuration is invalid. Initializing with placeholder values to prevent crashes.',
        );
        await Supabase.initialize(
          url: 'https://placeholder.supabase.co',
          anonKey: 'placeholder',
          debug: false,
        );
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
    }
  }

  static SupabaseClient get client {
    if (!Supabase.instance.isInitialized) {
      throw Exception('Supabase not initialized');
    }
    return Supabase.instance.client;
  }
}
