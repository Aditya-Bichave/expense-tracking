class E2EMode {
  static const bool enabled = bool.fromEnvironment('E2E_MODE');

  static const String userId = 'e2e-local-user';
  static const String fullName = 'E2E Tester';
  static const String email = 'e2e@example.com';
  static const String currency = 'USD';
  static const String timezone = 'UTC';

  static const String supabaseUrl = 'http://127.0.0.1:54321';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJyb2xlIjoiYW5vbiIsImlhdCI6MCwiZXhwIjoyNTM0MDIzMDA3OTl9.'
      'e2e-signature';
}
