import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('SupabaseClientProvider', () {
    test('client throws Error/Exception if not initialized', () {
      // In test env, Supabase.instance isn't set, so accessing it throws AssertionError from the library.
      // We catch anything to satisfy coverage of that line.
      expect(() => SupabaseClientProvider.client, throwsA(anything));
    });
  });
}
