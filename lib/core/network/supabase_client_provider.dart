import 'package:expense_tracker/core/network/supabase_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class SupabaseClientProvider {
  static Future<void> initialize() async {
    try {
      if (!SupabaseConfig.isValid) {
        log.warning(
          'Supabase configuration is invalid. Initializing with placeholder values to prevent crashes.',
        );
        // Initialize with dummy values so Supabase.instance.client doesn't throw.
        // This is critical for CI/Smoke tests where secrets might be missing.
        await Supabase.initialize(
          url: 'https://placeholder.supabase.co',
          anonKey: 'placeholder',
          debug: false,
        );
        return;
      }

      const storage = FlutterSecureStorage();
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      log.info('Supabase initialized successfully.');
    } catch (e) {
      log.severe('Failed to initialize Supabase: $e');
      // Do not rethrow to prevent app crash in CI/Smoke tests
    }
  }

  static SupabaseClient get client {
    if (!Supabase.instance.isInitialized) {
      // Should not happen if initialize() is called, even with placeholders.
      throw Exception('Supabase not initialized');
    }
    return Supabase.instance.client;
  }
}
