import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const String supabasePersistSessionKey =
      'SUPABASE_PERSIST_SESSION_KEY';

  static const String profileAvatarsBucket = 'avatars';
  static const String profilesTable = 'profiles';

  static bool get isValid =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseUrl !=
          'https://placeholder.supabase.co' && // Ensure real values are used
      supabaseAnonKey != 'INSERT_ANON_KEY_HERE';
}
