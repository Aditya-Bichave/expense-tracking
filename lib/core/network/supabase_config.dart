import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nzjqjsrdmbrojukbebzi.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'INSERT_ANON_KEY_HERE',
  );

  static const String supabasePersistSessionKey =
      'SUPABASE_PERSIST_SESSION_KEY';

  static bool get isValid =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'INSERT_ANON_KEY_HERE';
}
