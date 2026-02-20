import 'package:expense_tracker/core/network/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SupabaseConfig constants are set', () {
    expect(SupabaseConfig.supabaseUrl, isNotNull);
    expect(SupabaseConfig.supabaseAnonKey, isNotNull);
  });

  test('isValid checks logic correctly', () {
    // We can't change the static consts, so we check if the current values satisfy the logic
    final expectedIsValid =
        SupabaseConfig.supabaseUrl.isNotEmpty &&
        SupabaseConfig.supabaseAnonKey.isNotEmpty &&
        SupabaseConfig.supabaseAnonKey != 'INSERT_ANON_KEY_HERE';

    expect(SupabaseConfig.isValid, equals(expectedIsValid));
  });
}
