import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/core/network/supabase_config.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('SupabaseClientProvider', () {
    test('client throws Exception if not initialized', () {
      // Assuming Supabase.instance.isInitialized returns false in test env by default
      expect(() => SupabaseClientProvider.client, throwsA(isA<Exception>()));
    });

    // Note: Testing initialize() directly is hard because it calls static Supabase.initialize.
    // We rely on the integration/smoke tests for the happy path.
    // However, we can test the fallback logic if we can mock SupabaseConfig.isValid to return false.
    // Since SupabaseConfig.isValid is a static getter, we can't easily mock it without
    // wrapping it or using a more advanced mocking tool which isn't available here.
    //
    // We will accept the coverage hit on the static method but ensure other parts are covered.
  });
}
