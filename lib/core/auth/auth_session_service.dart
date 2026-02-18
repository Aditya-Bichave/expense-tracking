import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/network/supabase_client_provider.dart';

class AuthSessionService {
  final SupabaseClient _client;

  AuthSessionService() : _client = SupabaseClientProvider.client;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentSession != null;

  Future<void> signInWithOtp({required String phone}) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<void> verifyOtp({required String phone, required String token}) async {
    await _client.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
