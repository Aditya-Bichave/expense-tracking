import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<void> signInWithOtp({required String phone});
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  });
  Future<void> signOut();
  User? getCurrentUser();
  Stream<AuthState> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<void> signInWithOtp({required String phone}) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    return await _client.auth.verifyOTP(
      type: OtpType.sms,
      token: token,
      phone: phone,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
