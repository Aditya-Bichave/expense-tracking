import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/network/supabase_config.dart';

class SupabaseClientProvider {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
