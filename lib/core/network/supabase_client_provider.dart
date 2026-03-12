import 'package:flutter/foundation.dart';
import 'package:expense_tracker/core/network/supabase_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/core/utils/e2e_mode.dart';
import 'package:expense_tracker/core/network/web_local_storage.dart';

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
      log.fine('Initializing Supabase...');
      final useLocalE2EConfig = E2EMode.enabled && !SupabaseConfig.isValid;
      if (!useLocalE2EConfig && !SupabaseConfig.isValid) {
        // SECURITY FIX: Do not initialize with placeholders in production.
        // It's better to crash/fail initialization than to leak confusing "placeholder" states
        // or risk connecting to unsecured endpoints.
        throw Exception(
          'Supabase configuration is invalid. Please check your build configuration.',
        );
      }

      final url = useLocalE2EConfig
          ? E2EMode.supabaseUrl
          : SupabaseConfig.supabaseUrl;
      final anonKey = useLocalE2EConfig
          ? E2EMode.supabaseAnonKey
          : SupabaseConfig.supabaseAnonKey;

      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

      // On Web, FlutterSecureStorage uses encryption with a key stored in localStorage.
      // This makes E2E session injection difficult. SharedPreferences on Web uses
      // plain localStorage with a "flutter." prefix, which is easy to inject.
      final localStorage = kIsWeb
          ? getWebLocalStorage()
          : SecureLocalStorage(secureStorage);

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          localStorage: localStorage,
        ),
      );
      log.info('Supabase initialized successfully.');
    } catch (e) {
      log.severe('Failed to initialize Supabase: $e');
      // Rethrow to ensure main.dart catches it and shows InitializationErrorApp
      rethrow;
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
