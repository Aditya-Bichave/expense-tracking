import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSessionService {
  final SupabaseClient _client;
  final StreamController<User?> _userController =
      StreamController<User?>.broadcast();

  AuthSessionService(this._client) {
    _client.auth.onAuthStateChange.listen((data) {
      _userController.add(data.session?.user);
    });
  }

  Stream<User?> get userStream => _userController.stream;

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
