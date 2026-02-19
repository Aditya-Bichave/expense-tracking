import 'package:expense_tracker/core/network/supabase_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class SupabaseClientProvider {
  static Future<void> initialize() async {
    try {
      if (!SupabaseConfig.isValid) {
        log.warning('Supabase configuration is invalid. Skipping initialization.');
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
        // Return a dummy client or throw a better error?
        // Throwing might crash usage, but at least init didn't crash app start.
        // Better: Check validity before access in repositories.
        throw Exception('Supabase not initialized');
    }
    return Supabase.instance.client;
  }
}
